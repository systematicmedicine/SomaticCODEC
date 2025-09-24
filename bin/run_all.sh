#!/usr/bin/env bash
# ==============================================================================
# run_all.sh
#
# Master orchestration script to run the full bioinformatics pipeline:
#   1. Download inputs from S3
#   2. Check pipeline configuration (Snakemake dryrun)
#   3. Run pipeline (Snakemake)
#   4. Package outputs
#   5. Upload results to S3
#   6. Notify via SNS and shut down EC2 instance
#
# Logs:
#   - High-level: logs/bin_scripts/run_all.log
#   - Each step: logs/bin_scripts/<script>.log
#
# Exit:
#   - Returns non-zero exit code if any step fails.
#   - Sends SNS notification with status and shuts down instance.
#
# Authors:
#   - Cameron Fraser
#   - ChatGPT
# ==============================================================================
set -euo pipefail

# Define log
LOG_FILE="logs/bin_scripts/run_all.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[INFO] Starting run_all.sh: $(date)" | tee -a "$LOG_FILE"

# Load SNS ARN from config
SNS_ARN=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['aws']['sns_arn'])
")

# Define cleanup function
function handle_exit {
    local STATUS=$1
    local MSG=$2

    echo "[INFO] $MSG" | tee -a "$LOG_FILE"
    aws sns publish \
        --topic-arn "$SNS_ARN" \
        --subject "Pipeline $STATUS" \
        --message "$MSG"

    echo "[INFO] Shutting down instance..." | tee -a "$LOG_FILE"
    bash shutdown_instance.sh > logs/bin_scripts/shutdown_instance.log 2>&1
    exit 0
}

# Step 1
echo "[INFO] Step 1: download_S3.py" | tee -a "$LOG_FILE"
if ! python3 scripts/download_S3.py > logs/bin_scripts/download_S3.log 2>&1; then
    handle_exit "FAILED" "download_S3.py failed"
fi

# Step 2
echo "[INFO] Step 2: check_pipeline.sh" | tee -a "$LOG_FILE"
if ! bash bin/check_pipeline.sh > logs/bin_scripts/check_pipeline.log 2>&1; then
    handle_exit "FAILED" "check_pipeline.sh failed"
fi

# Step 3
echo "[INFO] Step 3: run_pipeline.sh" | tee -a "$LOG_FILE"
if ! bash bin/run_pipeline.sh > logs/bin_scripts/run_pipeline.log 2>&1; then
    handle_exit "FAILED" "run_pipeline.sh failed"
fi

# Step 4
echo "[INFO] Step 4: package_outputs.py" | tee -a "$LOG_FILE"
if ! python3 bin/package_outputs.py > logs/bin_scripts/package_outputs.log 2>&1; then
    handle_exit "FAILED" "package_outputs.py failed"
fi

# Step 5
echo "[INFO] Step 5: upload_S3.sh" | tee -a "$LOG_FILE"
if ! bash upload_S3.sh > logs/bin_scripts/upload_S3.log 2>&1; then
    handle_exit "FAILED" "upload_S3.sh failed"
fi

# ✅ Success case
handle_exit "SUCCEEDED" "Pipeline run completed successfully"


