#!/bin/bash

# Usage: ./compress_to_10mb.sh input.mp4 output.mp4

INPUT="$1"
OUTPUT="$2"
TARGET_MB=10
TARGET_BYTES=$((TARGET_MB * 1024 * 1024))

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: $0 input.mp4 output.mp4"
  exit 1
fi

# Get video duration in seconds using ffprobe
DURATION=$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

if [ -z "$DURATION" ]; then
  echo "Could not get duration of video."
  exit 1
fi

# Compute target total bitrate in bits per second (8 bits per byte)
# Reserve ~128 kbps for audio
TARGET_TOTAL_BITRATE=$((TARGET_BYTES * 8 / $(printf "%.0f" "$DURATION")))
AUDIO_BITRATE=128000
VIDEO_BITRATE=$((TARGET_TOTAL_BITRATE - AUDIO_BITRATE))

# Minimum sanity check
if [ "$VIDEO_BITRATE" -lt 50000 ]; then
  echo "Warning: Video is too long to compress under ${TARGET_MB}MB with decent quality."
  VIDEO_BITRATE=50000
fi

# Run ffmpeg with bitrate limits
ffmpeg -i "$INPUT" \
  -c:v libx264 -b:v "${VIDEO_BITRATE}" -maxrate "${VIDEO_BITRATE}" -bufsize "${VIDEO_BITRATE}" \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  "$OUTPUT"

# Show result
FINAL_SIZE=$(stat -c%s "$OUTPUT")
FINAL_MB=$((FINAL_SIZE / 1024 / 1024))
echo "Final size: ${FINAL_MB} MB"
