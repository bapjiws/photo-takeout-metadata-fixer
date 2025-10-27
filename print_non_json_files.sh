#!/bin/bash

# Usage: ./print_non_json_files.sh [folder]
# If no argument is given, the script exits.

if [ $# -eq 0 ]; then
  echo "Usage: $0 [folder]"
  exit 1
fi

FOLDER="$1"

if [ ! -d "$FOLDER" ]; then
  echo "The provided argument is not a folder."
  exit 1
fi

# Find and list files that are NOT JSON files
find "$FOLDER" -type f ! -name "*.json" | while read -r file; do
  echo "$file"
done

