#!/bin/bash
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

# Sleep for 60 seconds
echo "[INFO] Waiting 60 seconds before making shutdown request"
sleep 60

# Request shutdown
echo "[INFO] Requesting EC2 instance stop..."
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION"

echo "[INFO] Shutdown request sent for instance: $INSTANCE_ID"
