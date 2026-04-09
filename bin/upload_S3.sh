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
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

# Load parameters
while getopts "s:" opt; do
  case $opt in
    s) S3_TARGET_DIR="$OPTARG" ;;
    *) 
      echo "Usage: bash $0 -s <S3_target_dir>"
      exit 1
      ;;
  esac
done

if [[ -z "${S3_TARGET_DIR:-}" ]]; then
  echo "[ERROR] Missing required flags."
  echo "Usage: bash $0 -s <S3_target_dir>"
  exit 1
fi

RUNTIME_CONFIG="tmp/runtime_config/merged_config.yaml"

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
