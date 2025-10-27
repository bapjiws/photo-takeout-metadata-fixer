#!/bin/bash
export LC_ALL=en_US.UTF-8
# usage: ./set_dates_from_json_exiftool.sh <media_folder> <json_folder>
# Example: ./set_dates_from_json_exiftool.sh ./photos ./json

MEDIA_DIR="$1"
JSON_DIR="$2"

if [ -z "$MEDIA_DIR" ] || [ -z "$JSON_DIR" ]; then
  echo "Usage: $0 <media_folder> <json_folder>"
  exit 1
fi

if [ ! -d "$MEDIA_DIR" ]; then
  echo "Error: media folder not found: $MEDIA_DIR"
  exit 1
fi

if [ ! -d "$JSON_DIR" ]; then
  echo "Error: json folder not found: $JSON_DIR"
  exit 1
fi

shopt -s nullglob

for file in "$MEDIA_DIR"/*; do
  # Skip JSON files immediately for efficiency
  [[ "$file" == *.json ]] && continue
  [ -d "$file" ] && continue
  # [[ "$file" == *.json ]] && continue

  filename=$(basename "$file")
  json_file=$(find "$JSON_DIR" -name "$filename.json" -o -name "$filename.suppl.json" | head -n 1)

  if [ ! -f "$json_file" ]; then
    echo "No JSON found for: $filename"
    continue
  fi

  raw_date=$(jq -r '.photoTakenTime.formatted // empty' "$json_file" 2>/dev/null)
  if [ -z "$raw_date" ]; then
    echo "No date found in JSON for: $filename"
    continue
  fi

  # Normalize all Unicode spaces to ASCII space, strip trailing ' UTC'
  clean_date=$(echo "$raw_date" | perl -CS -pe 's/\s+/ /g; s/\x{202F}/ /g; s/\x{00A0}/ /g' | sed 's/ UTC$//')

  # Parse date without timezone (%Z) on macOS using date -j -f
  normalized=$(date -j -f "%b %e, %Y, %l:%M:%S %p" "$clean_date" "+%Y:%m:%d %H:%M:%S" 2>/dev/null)

  if [ -z "$normalized" ]; then
    echo "Failed to parse date '$raw_date' for: $filename"
    continue
  fi

  exiftool -overwrite_original \
    "-CreateDate=$normalized" \
    "-DateTimeOriginal=$normalized" \
    "-ModifyDate=$normalized" \
    "-MediaCreateDate=$normalized" \
    "-ContentCreateDate=$normalized" \
    "-TrackCreateDate=$normalized" \
    "-FileCreateDate=$normalized" \
    "-FileModifyDate=$normalized" \
    "$file" >/dev/null

  if [ $? -eq 0 ]; then
    echo "Set all EXIF and file dates for '$filename' to $normalized"
  else
    echo "Failed to update EXIF dates for '$filename'"
  fi
done
