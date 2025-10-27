#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 \"<time string>\" <filename>"
  exit 1
fi

time_input="$1"
file="$2"

# Try date parsing with multiple common formats for better success on macOS

formats=(
  "%b %d %Y %I:%M%p"   # e.g. May 11 2018 1:45PM
  "%B %d %Y %I:%M%p"   # e.g. May 11 2018 1:45PM (full month name)
  "%m/%d/%Y %I:%M%p"   # e.g. 05/11/2018 1:45PM
  "%Y-%m-%d %H:%M:%S"  # e.g. 2018-05-11 13:45:00
)

exif_date=""

for fmt in "${formats[@]}"; do
  parsed_date=$(date -j -f "$fmt" "$time_input" "+%Y:%m:%d %H:%M:%S" 2>/dev/null)
  if [ $? -eq 0 ]; then
    exif_date="$parsed_date"
    break
  fi
done

if [ -z "$exif_date" ]; then
  echo "Failed to parse date/time: $time_input"
  exit 1
fi

# Set typical creation/modification dates with exiftool
exiftool -overwrite_original \
  "-CreateDate=$exif_date" \
  "-DateTimeOriginal=$exif_date" \
  "-ModifyDate=$exif_date" \
  "-MediaCreateDate=$exif_date" \
  "-ContentCreateDate=$exif_date" \
  "-TrackCreateDate=$exif_date" \
  "-FileCreateDate=$exif_date" \
  "-FileModifyDate=$exif_date" \
  "$file"

echo "Set create/modify dates of '$file' to '$exif_date'"
