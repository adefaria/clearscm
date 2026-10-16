#!/bin/bash

# Check if a filename was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <video_file>"
  exit 1
fi

INPUT_FILE="$1"

# Check if the file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' not found."
  exit 1
fi

# Get the file extension and define a temporary output file
EXTENSION="${INPUT_FILE##*.}"
DIR="$(dirname "$INPUT_FILE")"
BASENAME="$(basename "$INPUT_FILE" ."$EXTENSION")"
TEMP_FILE="${DIR}/${BASENAME}_temp_stereo.${EXTENSION}"

echo "Processing '$INPUT_FILE' (converting left audio channel to stereo)..."

# Run ffmpeg:
# - c:v copy: copies the video stream without re-encoding (fast)
# - filter_complex "[0:a]pan=stereo|c0=c0|c1=c0[a]": takes the first audio channel (c0) and maps it to both output channels (c0 and c1)
# - c:a aac: encodes the audio to AAC (standard for MP4/MKV)
# - map 0:v: maps the video stream
# - map "[a]": maps the processed audio stream
ffmpeg -i "$INPUT_FILE" -c:v copy -filter_complex "[0:a]pan=stereo|c0=c0|c1=c0[a]" -map 0:v -map "[a]" -c:a aac -b:a 192k "$TEMP_FILE"

# Check if ffmpeg succeeded
if [ $? -eq 0 ]; then
  # Replace the original file with the temporary processed file
  mv "$TEMP_FILE" "$INPUT_FILE"
  echo "Successfully updated '$INPUT_FILE' in place."
else
  echo "Error: ffmpeg processing failed."
  rm -f "$TEMP_FILE"
  exit 1
fi
