#!/bin/bash
# deploy.sh
#
# This script deploys files from a given source directory (which should contain a file tree with directories such as
# /etc, /usr, /lib, etc.) to the target system (assumed to be /). It will only copy a file if it doesn't already exist.
#
# Additionally, it normalizes paths by removing arch-specific directories:
#   - /usr/lib/arm-linux-gnueabihf/  becomes  /usr/lib/
#   - /lib/arm-linux-gnueabihf/       becomes  /lib/
#
# Usage:
#   sudo ./deploy.sh <source_directory>
#
# Example:
#   sudo ./deploy.sh /tmp/final_rootfs

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <source_directory>"
  exit 1
fi

SRC="$1"

echo "Deploying files from $SRC ..."

# Walk through each file (not directory) in the source directory
find "$SRC" -type f | while read -r file; do
  # Get the relative path from the source directory
  rel_path="${file#$SRC/}"
  
  # Normalize paths: Remove arch-specific subdirectories
  # Replace "usr/lib/arm-linux-gnueabihf/" with "usr/lib/"
  #echo $norm_path
  norm_path=$(echo "$rel_path" | sed 's|/arm-linux-gnueabihf/|/|')
  #echo $norm_path
  # Replace "lib/arm-linux-gnueabihf/" with "lib/"
  norm_path=$(echo "$norm_path" | sed 's|/arm-linux-gnueabihf/|/|')
  #echo $norm_path
  
  dest="/$norm_path"
  
  # Only deploy the file if it doesn't already exist on the target
  if [ ! -f "$dest" ]; then
    echo "Deploying $file -> $dest ..."
    # Create the destination directory if needed
    mkdir -p "$(dirname "$dest")"
    # Copy the file preserving permissions and timestamps
    cp -p "$file" "$dest"
  else
    echo "Skipping $dest (already exists)"
  fi
done

echo "Deployment complete."
