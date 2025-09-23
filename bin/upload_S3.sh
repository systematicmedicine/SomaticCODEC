#!/usr/bin/env bash
set -euo pipefail

# Check that this script is being run from the project root
if [[ ! -f "config/config.yaml" || ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

# Hard-coded target bucket/prefix
S3_TARGET="arn:aws:s3:::sysmed-tmp-s3"

# Loop through all .tar.gz files in PROJECT_ROOT
for f in ./*.tar.gz; do
  if [[ -f "$f" ]]; then
    echo "[INFO] Uploading $f → $S3_TARGET/"
    aws s3 cp "$f" "$S3_TARGET/"
  fi
done
