#!/bin/bash

# Usage: ./compress_to_10mb.sh input.mp4 output.mp4
INPUT="$1"
OUTPUT="$2"
TARGET_MB=10
TARGET_BYTES=$((TARGET_MB * 1024 * 1024))

# Validate args
if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "❌ Usage: $0 input.mp4 output.mp4"
  exit 1
fi

# Function to install ffmpeg
install_ffmpeg() {
  echo "🔍 ffmpeg not found. Attempting to install..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &> /dev/null; then
      echo "❌ Homebrew not found. Please install it from https://brew.sh"
      exit 1
    fi
    brew install ffmpeg
  elif [[ -f /etc/debian_version ]]; then
    sudo apt update && sudo apt install -y ffmpeg
  else
    echo "❌ Unsupported OS. Please install ffmpeg manually."
    exit 1
  fi
}

# Check for ffmpeg and ffprobe
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
  install_ffmpeg
fi

# Get duration in seconds
DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

if [ -z "$DURATION" ]; then
  echo "❌ Could not read video duration."
  exit 1
fi

# Bitrate calculation
TARGET_TOTAL_BITRATE=$((TARGET_BYTES * 8 / $(printf "%.0f" "$DURATION")))
AUDIO_BITRATE=128000
VIDEO_BITRATE=$((TARGET_TOTAL_BITRATE - AUDIO_BITRATE))

# Sanity check
if [ "$VIDEO_BITRATE" -lt 50000 ]; then
  echo "⚠️ Video too long to compress under ${TARGET_MB}MB with decent quality."
  VIDEO_BITRATE=50000
fi

# Run compression
echo "🎬 Compressing with video bitrate: $((VIDEO_BITRATE / 1000)) kbps"
ffmpeg -i "$INPUT" \
  -c:v libx264 -b:v "${VIDEO_BITRATE}" -maxrate "${VIDEO_BITRATE}" -bufsize "${VIDEO_BITRATE}" \
  -c:a aac -b:a 128k -movflags +faststart "$OUTPUT"

# Result
FINAL_SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || stat -f%z "$OUTPUT")
FINAL_MB=$((FINAL_SIZE / 1024 / 1024))
echo "✅ Done. Output size: ${FINAL_MB} MB"
