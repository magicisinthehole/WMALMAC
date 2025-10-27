import Foundation
import Combine

class AudioEncoder: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var currentFile = ""
    @Published var statusMessage = ""
    @Published var encodingFileURL: URL?
    @Published var completedFileURLs: Set<URL> = []

    private let resourcesPath: String = {
        let bundlePath = Bundle.main.bundleURL.path
        return "\(bundlePath)/Contents/Resources/Resources"
    }()

    private var ffmpegPath: String { "\(resourcesPath)/ffmpeg" }
    private var ffprobePath: String { "\(resourcesPath)/ffprobe" }

    private let progressLock = NSLock()
    private var completedCount = 0
    private let maxConcurrentEncodes = 4

    private func getAudioProperties(from fileURL: URL) -> (bitDepth: Int, sampleRate: Int)? {
        let pipe = Pipe()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ffprobePath)
        task.arguments = [
            "-v", "error",
            "-select_streams", "a:0",
            "-show_entries", "stream=bits_per_sample,sample_rate",
            "-of", "default=noprint_wrappers=1:nokey=1:noinput_prefix=1",
            fileURL.path
        ]
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let values = output.split(separator: "\n").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

            var bitDepth = 16, sampleRate = 48000
            for value in values {
                if value > 10000 { sampleRate = value }
                else if value < 1000 { bitDepth = value }
            }

            return (bitDepth, sampleRate)
        } catch {
            print("Error probing audio: \(error)")
            return nil
        }
    }

    private func roundUpEncoding(_ bitDepth: Int, _ sampleRate: Int) -> (bitDepth: Int, sampleRate: Int) {
        let newBitDepth = bitDepth > 16 ? 24 : 16
        let sampleRateKHz = sampleRate / 1000
        let newSampleRate: Int
        switch sampleRateKHz {
        case ..<44: newSampleRate = 44
        case 44...48: newSampleRate = 48
        default: newSampleRate = 96
        }
        return (newBitDepth, newSampleRate)
    }

    func encode(files: [URL], outputDirectory: URL?, outputMode: String, subfolderName: String, encodingMode: String, bitDepth: Int, sampleRate: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.updateUI(isProcessing: true, progress: 0, encodingFileURL: nil)
            self.progressLock.lock()
            self.completedCount = 0
            self.progressLock.unlock()
            DispatchQueue.main.async {
                self.completedFileURLs.removeAll()
            }

            let totalFiles = files.count
            let semaphore = DispatchSemaphore(value: self.maxConcurrentEncodes)
            let dispatchGroup = DispatchGroup()

            for file in files {
                dispatchGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    semaphore.wait()
                    defer { semaphore.signal() }

                    guard let outputPath = self.getOutputPath(for: file, mode: outputMode, directory: outputDirectory, subfolder: subfolderName) else {
                        self.updateUI(statusMessage: "✗ Failed: Invalid output path")
                        self.incrementProgress(total: totalFiles)
                        dispatchGroup.leave()
                        return
                    }

                    self.updateUI(currentFile: file.lastPathComponent, statusMessage: "Encoding: \(file.lastPathComponent)...", encodingFileURL: file)

                    let (finalBitDepth, finalSampleRate) = encodingMode == "auto"
                        ? (self.getAudioProperties(from: file).map { self.roundUpEncoding($0.bitDepth, $0.sampleRate) } ?? (16, 48))
                        : (bitDepth, sampleRate)

                    let success = self.encodeFile(
                        inputPath: file.path,
                        outputPath: outputPath,
                        bitDepth: finalBitDepth,
                        sampleRate: finalSampleRate,
                        fileURL: file
                    )

                    let outputFileName = file.deletingPathExtension().lastPathComponent + ".wma"

                    if success {
                        DispatchQueue.main.async {
                            self.completedFileURLs.insert(file)
                        }
                    }

                    self.updateUI(
                        statusMessage: success ? "✓ Completed: \(outputFileName)" : "✗ Failed: \(file.lastPathComponent)"
                    )

                    self.incrementProgress(total: totalFiles)
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.wait()
            self.updateUI(isProcessing: false, progress: 1.0, statusMessage: "Encoding completed!", encodingFileURL: nil)
        }
    }

    private func incrementProgress(total: Int) {
        self.progressLock.lock()
        self.completedCount += 1
        let progress = Double(self.completedCount) / Double(total)
        self.progressLock.unlock()
        self.updateUI(progress: progress)
    }

    private func getOutputPath(for file: URL, mode: String, directory: URL?, subfolder: String) -> String? {
        let outputFileName = file.deletingPathExtension().lastPathComponent + ".wma"

        switch mode {
        case "custom":
            guard let dir = directory else { return nil }
            return dir.appendingPathComponent(outputFileName).path

        case "sameAsInput":
            return file.deletingLastPathComponent().appendingPathComponent(outputFileName).path

        case "subfolder":
            let inputDir = file.deletingLastPathComponent()
            let subfolderURL = inputDir.appendingPathComponent(subfolder)
            do {
                try FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
                return subfolderURL.appendingPathComponent(outputFileName).path
            } catch {
                print("Failed to create subfolder: \(error)")
                return nil
            }

        default:
            return nil
        }
    }

    private func updateUI(isProcessing: Bool? = nil, progress: Double? = nil, currentFile: String? = nil, statusMessage: String? = nil, encodingFileURL: URL? = nil) {
        DispatchQueue.main.async {
            if let isProcessing = isProcessing { self.isProcessing = isProcessing }
            if let progress = progress { self.progress = progress }
            if let currentFile = currentFile { self.currentFile = currentFile }
            if let statusMessage = statusMessage { self.statusMessage = statusMessage }
            if encodingFileURL != nil { self.encodingFileURL = encodingFileURL }
        }
    }

    private func encodeFile(inputPath: String, outputPath: String, bitDepth: Int, sampleRate: Int, fileURL: URL? = nil) -> Bool {
        let pipe = Pipe()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ffmpegPath)
        task.arguments = [
            "-i", inputPath,
            "-c:a", "wmalossless",
            "-ar", "\(sampleRate)000",
            "-bits_per_raw_sample", "\(bitDepth)",
            "-y", outputPath
        ]
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error running ffmpeg: \(error)")
            self.updateUI(statusMessage: "✗ Error: \(error.localizedDescription)")
            return false
        }
    }
}
