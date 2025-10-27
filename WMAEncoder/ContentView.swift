import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var encoder = AudioEncoder()
    @State private var selectedFiles: [URL] = []
    @State private var outputDirectory: URL?
    @State private var bitDepth = 16
    @State private var sampleRate = 48
    @State private var isEncoding = false
    @State private var showEncodingOptions = false
    @State private var fileTypeFilter = "All"
    @State private var outputMode = "custom"
    @State private var subfolderName = "WMA Output"
    @State private var encodingMode = "manual"

    var filteredFiles: [URL] {
        if fileTypeFilter == "All" {
            return selectedFiles
        }
        return selectedFiles.filter { $0.pathExtension.lowercased() == fileTypeFilter.lowercased() }
    }

    var uniqueFileTypes: [String] {
        let types = Set(selectedFiles.map { $0.pathExtension.lowercased() })
        return types.sorted()
    }

    func countFiles(ofType type: String) -> Int {
        return selectedFiles.filter { $0.pathExtension.lowercased() == type.lowercased() }.count
    }

    var canEncode: Bool {
        if selectedFiles.isEmpty || filteredFiles.isEmpty || encoder.isProcessing {
            return false
        }
        if outputMode == "custom" && outputDirectory == nil {
            return false
        }
        return true
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("WMA Lossless Encoder")
                    .font(.system(size: 24, weight: .bold))
                Text("Convert audio files to WMA Lossless format")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)

            Divider()

            // File Selection Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Source Files")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))

                    VStack(spacing: 4) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)

                        Text("Drag audio files here or click to select")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: selectedFiles.isEmpty ? nil : 70)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
                .onTapGesture {
                    selectFiles()
                }

                if !selectedFiles.isEmpty {
                    HStack {
                        Text("Total: \(selectedFiles.count) · Selected: \(filteredFiles.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("Filter", selection: $fileTypeFilter) {
                            Text("All").tag("All")
                            ForEach(uniqueFileTypes, id: \.self) { type in
                                Text(type.uppercased()).tag(type)
                            }
                        }
                        .frame(width: 120)
                        .font(.system(size: 11))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(4)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(filteredFiles, id: \.self) { file in
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.lastPathComponent)
                                            .font(.system(size: 12))
                                        Text(file.path)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()

                                    if encoder.completedFileURLs.contains(file) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .frame(width: 20, height: 20)
                                    } else if encoder.encodingFileURL == file {
                                        ProgressView()
                                            .scaleEffect(0.5)
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Color.clear
                                            .frame(width: 20, height: 20)
                                    }

                                    Button(action: {
                                        selectedFiles.removeAll { $0 == file }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .cornerRadius(4)
                }
            }

            Spacer()

            Divider()

            // Encoding Options
            DisclosureGroup(isExpanded: $showEncodingOptions) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Encoding Mode", selection: $encodingMode) {
                        Text("Auto (per file)").tag("auto")
                        Text("Manual").tag("manual")
                    }
                    .pickerStyle(.radioGroup)
                    .font(.system(size: 11))

                    if encodingMode == "manual" {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bit Depth")
                                    .font(.system(size: 11, weight: .medium))
                                Text("bits")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Picker("Bit Depth", selection: $bitDepth) {
                                Text("16-bit").tag(16)
                                Text("24-bit").tag(24)
                            }
                            .frame(width: 180)
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sample Rate")
                                    .font(.system(size: 11, weight: .medium))
                                Text("kHz")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Picker("Sample Rate", selection: $sampleRate) {
                                Text("44.1 kHz").tag(44)
                                Text("48 kHz").tag(48)
                                Text("96 kHz").tag(96)
                            }
                            .frame(width: 180)
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                    } else {
                        Text("Files will be encoded with their original properties (rounded to closest supported format)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(4)
                    }
                }
            } label: {
                HStack {
                    Text("Encoding Options")
                    Spacer()
                    if !showEncodingOptions {
                        if encodingMode == "auto" {
                            Text("Auto")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(bitDepth)-bit · \(sampleRate) kHz")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .font(.system(size: 13, weight: .semibold))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    showEncodingOptions.toggle()
                }
            }

            Divider()

            // Output Directory
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Location")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Picker("Output Mode", selection: $outputMode) {
                        Text("Custom Folder").tag("custom")
                        Text("Same as Input").tag("sameAsInput")
                        Text("Subfolder in Input").tag("subfolder")
                    }
                    .pickerStyle(.radioGroup)
                    .font(.system(size: 11))

                    if outputMode == "custom" {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let output = outputDirectory {
                                    Text(output.path)
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                } else {
                                    Text("Not selected")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundColor(.red)
                                }
                            }
                            Spacer()
                            Button("Browse", action: selectOutputDirectory)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                    }

                    if outputMode == "subfolder" {
                        HStack {
                            Text("Subfolder Name:")
                                .font(.system(size: 11, weight: .medium))
                            TextField("Subfolder", text: $subfolderName)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Status Section
            if !encoder.statusMessage.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(encoder.statusMessage)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                        .lineLimit(3)
                }
            }

            // Progress
            if encoder.isProcessing {
                VStack(spacing: 4) {
                    ProgressView(value: encoder.progress)
                        .tint(.blue)
                    HStack {
                        Text(encoder.currentFile)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", encoder.progress * 100))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    selectedFiles.removeAll()
                    outputDirectory = nil
                    fileTypeFilter = "All"
                    outputMode = "custom"
                    subfolderName = "WMA Output"
                    encodingMode = "manual"
                }) {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .disabled(selectedFiles.isEmpty && outputDirectory == nil)

                Button(action: startEncoding) {
                    if encoder.isProcessing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7, anchor: .center)
                            Text("Encoding...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Encode to WMA")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 6)
                .foregroundColor(.white)
                .background(canEncode ? Color.blue : Color.gray)
                .cornerRadius(4)
                .disabled(!canEncode)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func selectFiles() {
        let dialog = NSOpenPanel()
        dialog.title = "Select audio files or folders"
        dialog.allowedContentTypes = [
            .audio,
            .mp3,
            .wav,
            .aiff,
            UTType(filenameExtension: "flac", conformingTo: .audio) ?? .audio
        ]
        dialog.allowsMultipleSelection = true
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = true

        if dialog.runModal() == .OK {
            for url in dialog.urls {
                addFilesRecursively(from: url)
            }
        }
    }

    private func addFilesRecursively(from url: URL) {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return
        }

        if isDirectory.boolValue {
            // It's a directory, scan recursively
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if isAudioFile(fileURL) && !selectedFiles.contains(fileURL) {
                        selectedFiles.append(fileURL)
                    }
                }
            }
        } else {
            // It's a file
            if isAudioFile(url) && !selectedFiles.contains(url) {
                selectedFiles.append(url)
            }
        }
    }

    private func isAudioFile(_ url: URL) -> Bool {
        let audioExtensions = ["mp3", "wav", "aiff", "aif", "m4a", "flac", "ogg", "wma", "aac", "alac"]
        return audioExtensions.contains(url.pathExtension.lowercased())
    }

    private func selectOutputDirectory() {
        let dialog = NSOpenPanel()
        dialog.title = "Select output folder"
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false

        if dialog.runModal() == .OK {
            outputDirectory = dialog.urls.first
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: NSURL.self) { object, _ in
                if let url = object as? URL {
                    DispatchQueue.main.async {
                        addFilesRecursively(from: url)
                    }
                }
            }
        }
        return true
    }

    private func startEncoding() {
        guard !selectedFiles.isEmpty else { return }

        let finalBitDepth = encodingMode == "auto" ? 0 : bitDepth
        let finalSampleRate = encodingMode == "auto" ? 0 : sampleRate

        encoder.encode(
            files: filteredFiles,
            outputDirectory: outputDirectory,
            outputMode: outputMode,
            subfolderName: subfolderName,
            encodingMode: encodingMode,
            bitDepth: finalBitDepth,
            sampleRate: finalSampleRate
        )
    }
}

#Preview {
    ContentView()
}
