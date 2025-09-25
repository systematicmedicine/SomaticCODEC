#!/bin/bash
set -euo pipefail

echo "[INFO] Shutdown requested at: $(date -u)"
echo "[INFO] Requesting EC2 instance stop..."

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region ap-southeast-2

echo "[INFO] Shutdown request sent for instance: $INSTANCE_ID"

