#!/bin/bash

# Usage: ./fix_dates.sh [folder or files...]
# If no argument given, current directory is processed.

# Requires:
# - exiftool installed
# - SetFile installed (part of Xcode Command Line Tools)
# - macOS environment

FIELDS=(
  DateTimeOriginal
  CreateDate
  MediaCreateDate
  ContentCreateDate
  TrackCreateDate
  ModifyDate
)

if [ $# -eq 0 ]; then
  TARGETS=(*)
else
  TARGETS=("$@")
fi

for file in "${TARGETS[@]}"; do
  # Ignore directories and JSON files
  if [ -d "$file" ]; then
    echo "Skipping directory $file"
    continue
  fi

  # Skip JSON files
  if [[ "$file" == *.json ]]; then
    continue
  fi

  # Collect all valid dates here
  DATES=()

  for field in "${FIELDS[@]}"; do
    value=$(exiftool -s3 -"$field" "$file" 2>/dev/null || echo "")
    # Skip empty or invalid zero dates like "0000:00:00 00:00:00"
    if [[ -z "$value" ]] || [[ "$value" =~ ^0000|0000:00:00 ]]; then
      continue
    fi

    # Remove timezone offset (+02:00) if present
    value_no_tz=$(echo "$value" | sed 's/[+-][0-9]\{2\}:[0-9]\{2\}$//')

    # Validate format YYYY:MM:DD HH:MM:SS
    if [[ "$value_no_tz" =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
      DATES+=("$value_no_tz")
    fi
  done

  # Also include FileCreateDate and FileModifyDate if valid
  for sysfield in FileCreateDate FileModifyDate; do
    sysvalue=$(exiftool -s3 -"$sysfield" "$file" 2>/dev/null || echo "")
    if [[ -n "$sysvalue" ]] && ! [[ "$sysvalue" =~ ^0000 ]]; then
      sysvalue_no_tz=$(echo "$sysvalue" | sed 's/[+-][0-9]\{2\}:[0-9]\{2\}$//')
      if [[ "$sysvalue_no_tz" =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
        DATES+=("$sysvalue_no_tz")
      fi
    fi
  done

  if [ ${#DATES[@]} -eq 0 ]; then
    echo "No valid dates found for file: $file"
    continue
  fi

  # Get smallest (earliest) date
  earliest=$(printf "%s\n" "${DATES[@]}" | sort | head -n1)

  # Convert earliest date for touch and SetFile formats
  touch_date=$(echo "$earliest" | sed -E 's/([0-9]{4}):([0-9]{2}):([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/\1\2\3\4\5.\6/')
  setfile_date=$(echo "$earliest" | sed -E 's/([0-9]{4}):([0-9]{2}):([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/\2\/\3\/\1 \4:\5:\6/')

  # Apply the dates
  SetFile -d "$setfile_date" "$file" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Warning: SetFile command failed or not found. Install Xcode Command Line Tools."
  fi
  touch -t "$touch_date" "$file"

  echo "Updated $file to creation date $earliest"
done
