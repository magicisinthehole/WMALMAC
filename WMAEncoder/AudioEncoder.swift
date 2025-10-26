import Foundation
import Combine

class AudioEncoder: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var currentFile = ""
    @Published var statusMessage = ""

    private var ffmpegPath: String {
        let bundlePath = Bundle.main.bundleURL.path
        return "\(bundlePath)/Contents/Resources/ffmpeg"
    }

    func encode(files: [URL], outputDirectory: URL, bitDepth: Int, sampleRate: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.isProcessing = true
                self.progress = 0
            }

            let totalFiles = files.count
            for (index, file) in files.enumerated() {
                let outputFileName = file.deletingPathExtension().lastPathComponent + ".wma"
                let outputPath = outputDirectory.appendingPathComponent(outputFileName).path

                DispatchQueue.main.async {
                    self.currentFile = file.lastPathComponent
                    self.statusMessage = "Encoding: \(file.lastPathComponent)..."
                }

                let success = self.encodeFile(
                    inputPath: file.path,
                    outputPath: outputPath,
                    bitDepth: bitDepth,
                    sampleRate: sampleRate
                )

                DispatchQueue.main.async {
                    self.progress = Double(index + 1) / Double(totalFiles)
                    if success {
                        self.statusMessage = "✓ Completed: \(outputFileName)"
                    } else {
                        self.statusMessage = "✗ Failed: \(file.lastPathComponent)"
                    }
                }
            }

            DispatchQueue.main.async {
                self.isProcessing = false
                self.statusMessage = "Encoding completed!"
                self.progress = 1.0
            }
        }
    }

    private func encodeFile(inputPath: String, outputPath: String, bitDepth: Int, sampleRate: Int) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ffmpegPath)

        let args = [
            "-i", inputPath,
            "-c:a", "wmalossless",
            "-acodec", "wmalossless",
            "-ar", "\(sampleRate)000",
            "-bits_per_raw_sample", "\(bitDepth)",
            "-y",  // Overwrite output file
            outputPath
        ]

        task.arguments = args

        let pipe = Pipe()
        task.standardError = pipe
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            print("Error running ffmpeg: \(error)")
            return false
        }
    }
}
