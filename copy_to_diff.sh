#!/bin/bash

# Check for 2 arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 folder_1 folder_2"
  exit 1
fi

folder_1=$1
folder_2=$2
diff_dir="$(dirname "$folder_1")/diff"

# Create diff directory if it doesn't exist
mkdir -p "$diff_dir"

# Loop through each item in folder_2
for item in "$folder_2"/*; do
  base_item=$(basename "$item")
  if [ ! -e "$folder_1/$base_item" ]; then
    cp -r "$item" "$diff_dir/"
    echo "Copied: $base_item"
  fi
done
