#!/bin/bash
#
# --- shutdown_instance.sh ---
#
# Shuts down EC2 instance following a successful or failed run.
#
# Authors:
#   - Cameron Fraser
#   - ChatGPT
#
set -euo pipefail

echo "[INFO] Shutdown requested at: $(date -u)"

# Show the values for debugging
echo "[INFO] INSTANCE_ID: ${INSTANCE_ID:-"(not set)"}"
echo "[INFO] AWS_REGION: ${AWS_REGION:-"(not set)"}"

# Safety check
if [[ -z "${INSTANCE_ID:-}" || -z "${AWS_REGION:-}" ]]; then
  echo "[ERROR] Missing INSTANCE_ID or AWS_REGION. Aborting shutdown."
  exit 1
fi

# Request shutdown
echo "[INFO] Requesting EC2 instance stop..."
sleep 5
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION"

echo "[INFO] Shutdown request sent for instance: $INSTANCE_ID"
