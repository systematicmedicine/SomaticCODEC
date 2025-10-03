#!/usr/bin/env bash
# ==============================================================================
# upload_S3.sh
#
# Script for uploading pipeline outputs to S3
#
# Authors:
#   - Cameron Fraser
#   - ChatGPT
# ==============================================================================
set -euo pipefail

echo "[INFO] Starting upload_S3.sh: $(date)"

# Check that this script is being run from the project root
if [[ ! -f "config/config.yaml" || ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

# Read S3 bucket ARN from config
S3_TARGET=$(python3 -c "
import yaml
try:
    with open('config/config.yaml') as f:
        cfg = yaml.safe_load(f)
    print(cfg['infrastructure']['aws']['s3_bucket'].rstrip('/'))
except Exception as e:
    import sys
    print(f'[ERROR] Failed to read upload.s3_bucket from config.yaml: {e}', file=sys.stderr)
    sys.exit(1)
")

echo "[INFO] Target S3 bucket: $S3_TARGET"

# Upload all .tar.gz files in project root
for f in ./*.tar.gz; do
  if [[ -f "$f" ]]; then
    echo "[INFO] Uploading $f → $S3_TARGET/"
    if ! aws s3 cp "$f" "$S3_TARGET/"; then
      echo "[ERROR] Upload failed for $f"
      exit 1
    fi
  fi
done

echo "[INFO] Completed upload_S3.sh: $(date)"
