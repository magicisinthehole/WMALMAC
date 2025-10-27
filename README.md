# WMA Lossless Encoder

A macOS application for encoding audio files to WMA Lossless format.

## Features

- Drag and drop file selection
- Supports MP3, WAV, AIFF, FLAC, and other audio formats
- Recursive folder scanning
- File type filtering
- Three output location modes:
  - Custom folder
  - Same directory as input files
  - Subfolder within input file directories
- Configurable encoding options:
  - Auto mode: matches input file properties (bit depth and sample rate)
  - Manual mode: 16-bit or 24-bit depth, 44.1/48/96 kHz sample rate
- Batch encoding with parallel processing (up to 4 concurrent files)
- Per-file encoding status with visual indicators
- Uses [WMA Lossless encoder for FFmpeg](https://github.com/magicisinthehole/FFmpeg/tree/wma-lossless-encoder)

## Screenshot

![WMA Encoder Interface](screenshot.png)

## System Requirements

- macOS 12.0 or later
- Apple Silicon (arm64) or Intel (x86_64) processor

## Installation

1. Download the DMG from releases
2. Drag WMAEncoder.app to your Applications folder
3. Launch the application

## Usage

1. **Add Files**
   - Drag audio files or folders into the drop zone or click to browse
   - When selecting folders, all audio files in subdirectories are automatically added
   - Use the file type filter to view specific formats

2. **Set Encoding Options** (optional)
   - Expand "Encoding Options" to select encoding mode:
     - Auto: matches each file's original properties (default: 16-bit, 48 kHz)
     - Manual: specify bit depth (16-bit or 24-bit) and sample rate (44.1/48/96 kHz)

3. **Select Output Location**
   - Choose output mode:
     - Custom Folder: select a specific directory
     - Same as Input: files are saved alongside originals
     - Subfolder in Input: files are saved in a subfolder (configurable name)

4. **Encode**
   - Click "Encode to WMA" to start
   - Up to 4 files encode simultaneously
   - Progress indicators show encoding status for each file
   - Green checkmark appears when each file completes

## Troubleshooting

**"Permission denied" errors**
- Check that the input and output folders are readable/writable

**Encoding fails**
- Verify the audio files are in a supported format
- Ensure the output directory is writable

**Application won't launch**
- Requires macOS 12.0 or later

## Technical Details

- Built with SwiftUI
- Bundled with [WMA Lossless encoder for FFmpeg](https://github.com/magicisinthehole/FFmpeg/tree/wma-lossless-encoder)
- Encoding runs locally

## License

Uses FFmpeg under GPL/LGPL licenses. The included FFmpeg binary is compiled with GPL support.
