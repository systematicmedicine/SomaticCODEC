#!/usr/bin/env bash
# 
# --- upload_S3.sh ---
#
# Script for uploading pipeline outputs to S3
#
# Authors:
#   - Cameron Fraser
# 
set -euo pipefail

echo "[INFO] Starting upload_S3.sh: $(date)"

# Check that this script is being run from the project root
if [[ ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

RUNTIME_CONFIG="tmp/runtime_config/merged_config.yaml"

# Check runtime config exists
if [[ ! -f "$RUNTIME_CONFIG" ]]; then
  echo "[ERROR] Runtime config not found at $RUNTIME_CONFIG"
  echo "[ERROR] Please run bin/create_runtime_config.py first."
  exit 1
fi

# Read S3 target from runtime config
S3_TARGET=$(python3 -c "
import yaml
try:
    with open('$RUNTIME_CONFIG') as f:
        cfg = yaml.safe_load(f)
    print(cfg['infrastructure']['aws']['s3_out_dir'].rstrip('/'))
except Exception as e:
    import sys
    print(f'[ERROR] Failed to read infrastructure.aws.s3_out_dir from runtime config: {e}', file=sys.stderr)
    sys.exit(1)
")

echo "[INFO] Using config: $RUNTIME_CONFIG"
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
