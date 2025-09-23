#!/usr/bin/env bash

# Sends message to info@sytematicmedicine.com

set -euo pipefail

# ---- Config ----
SNS_TOPIC_ARN="arn:aws:sns:ap-southeast-2:554765025175:ec2-pipeline-complete"
SUBJECT="Pipeline update"

# ---- Input ----
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"message to send\""
  exit 1
fi

MESSAGE="$1"

# ---- Send message ----
aws sns publish \
  --topic-arn "$SNS_TOPIC_ARN" \
  --subject "$SUBJECT" \
  --message "$MESSAGE"