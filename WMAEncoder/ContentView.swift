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

    var body: some View {
        VStack(spacing: 16) {
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
            VStack(alignment: .leading, spacing: 12) {
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
                .frame(maxWidth: .infinity, maxHeight: 70)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
                .onTapGesture {
                    selectFiles()
                }

                if !selectedFiles.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(selectedFiles, id: \.self) { file in
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
                    .frame(maxHeight: 300)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .cornerRadius(4)
                }
            }

            Divider()

            // Encoding Options
            DisclosureGroup(isExpanded: $showEncodingOptions) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(4)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(4)
                }
            } label: {
                HStack {
                    Text("Encoding Options")
                    Spacer()
                    if !showEncodingOptions {
                        Text("\(bitDepth)-bit · \(sampleRate) kHz")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output Folder")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
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
            }

            Spacer()

            // Status Section
            if !encoder.statusMessage.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text(encoder.statusMessage)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(4)
                        .lineLimit(3)
                }
            }

            // Progress
            if encoder.isProcessing {
                VStack(spacing: 8) {
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
                }) {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
                .padding(.vertical, 8)
                .foregroundColor(.white)
                .background(selectedFiles.isEmpty || outputDirectory == nil || encoder.isProcessing ? Color.gray : Color.blue)
                .cornerRadius(4)
                .disabled(selectedFiles.isEmpty || outputDirectory == nil || encoder.isProcessing)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func selectFiles() {
        let dialog = NSOpenPanel()
        dialog.title = "Select audio files"
        dialog.allowedContentTypes = [
            .audio,
            .mp3,
            .wav,
            .aiff,
            UTType(filenameExtension: "flac", conformingTo: .audio) ?? .audio
        ]
        dialog.allowsMultipleSelection = true
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true

        if dialog.runModal() == .OK {
            selectedFiles.append(contentsOf: dialog.urls)
        }
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
                        selectedFiles.append(url)
                    }
                }
            }
        }
        return true
    }

    private func startEncoding() {
        guard !selectedFiles.isEmpty, let outputDir = outputDirectory else { return }
        encoder.encode(
            files: selectedFiles,
            outputDirectory: outputDir,
            bitDepth: bitDepth,
            sampleRate: sampleRate
        )
    }
}

#Preview {
    ContentView()
}
