# WMA Lossless Encoder

A clean, modern macOS GUI for encoding audio files to WMA Lossless format using FFmpeg with WMA lossless encoder support.

## Features

- **Simple Drag & Drop Interface** - Drag audio files directly into the application or use the file selector
- **Multiple Audio Format Support** - Supports MP3, WAV, AIFF, FLAC, and other standard audio formats
- **Customizable Encoding Options**
  - Bit Rate: 128, 192, 256, or 320 kbps
  - Sample Rate: 44.1 kHz, 48 kHz, or 96 kHz
- **Batch Processing** - Encode multiple files at once
- **Real-time Progress** - See encoding progress with file-by-file status updates
- **Lossless Quality** - Uses FFmpeg's WMA Lossless encoder for perfect audio reproduction

## System Requirements

- macOS 12.0 or later
- Apple Silicon (arm64) or Intel (x86_64) processor

## Installation

1. Download the `WMAEncoder.app` bundle
2. Copy it to your Applications folder (optional but recommended)
3. Launch the application by double-clicking it

## Usage

1. **Select Audio Files**
   - Drag and drop audio files into the drop zone, or
   - Click the drop zone to browse and select files

2. **Choose Encoding Settings**
   - Select your desired Bit Rate (default: 192 kbps)
   - Select your desired Sample Rate (default: 48 kHz)

3. **Select Output Folder**
   - Click "Browse" to choose where your encoded WMA files will be saved

4. **Start Encoding**
   - Click "Encode to WMA" to begin the encoding process
   - Watch the progress bar as files are encoded
   - Encoded files will be saved with the same name as the original, with .wma extension

## Troubleshooting

**"Permission denied" errors**
- The app may need permission to access your audio files. Make sure the selected folder is readable.

**Encoding fails silently**
- Check that your audio files are in a supported format
- Ensure the output directory is writable

**Application won't launch**
- Make sure you have macOS 12.0 or later
- Try moving the app to the Applications folder

## Technical Details

- Built with SwiftUI for a modern native macOS experience
- Bundled with FFmpeg compiled with WMA Lossless encoder support
- All encoding is done locally on your machine - no cloud services or internet required

## License

This application uses FFmpeg, which is available under the GPL and LGPL licenses. The FFmpeg binaries included with this application were compiled with GPL support enabled.

For more information about FFmpeg, visit: https://ffmpeg.org

---

**Version:** 1.0
**Last Updated:** October 2025
