#!/usr/bin/env bash
# 
# --- upload_S3.sh ---
#
# Script for uploading pipeline outputs to S3
#
# Authors:
#   - Cameron Fraser
#   - Joshua Johnstone
# 
set -euo pipefail

echo "[INFO] Starting upload_S3.sh: $(date)"

# Check that this script is being run from the project root
if [[ ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root"
  exit 1
fi

# Load parameters
S3_TARGET_DIR=$1

echo "[INFO] Target S3 bucket: $S3_TARGET_DIR"

# Upload all .tar.gz files in project root
for f in ./*.tar.gz; do
  if [[ -f "$f" ]]; then
    echo "[INFO] Uploading $f → $S3_TARGET_DIR/"
    if ! aws s3 cp "$f" "$S3_TARGET_DIR/"; then
      echo "[ERROR] Upload failed for $f"
      exit 1
    fi
  fi
done

echo "[INFO] Completed upload_S3.sh: $(date)"
