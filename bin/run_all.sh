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
#   6. Notify via SNS
#   7. Shutdown instance
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

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

set -euo pipefail

# Define log
LOG_FILE="logs/bin_scripts/run_all.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[INFO] Starting run_all.sh: $(date)" | tee -a "$LOG_FILE"

# Load params from config
SNS_ARN=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['aws']['sns_arn'])
")

EXPERIMENT_NAME=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['experiment']['name'])
")

# Ensure required environment variables are set
: "${AWS_REGION:?AWS_REGION must be set}"
: "${INSTANCE_ID:?INSTANCE_ID must be set}"

# Define cleanup function
function handle_exit {
    local STATUS=$1
    local MSG=$2

    echo "[INFO] $MSG" | tee -a "$LOG_FILE"
    aws sns publish \
        --topic-arn "$SNS_ARN" \
        --subject "Pipeline $EXPERIMENT_NAME $STATUS" \
        --message "$MSG" \
        --region $AWS_REGION

    sleep 5

    echo "[INFO] Triggering EC2 shutdown..." | tee -a "$LOG_FILE"
    if ! bash bin/shutdown_instance.sh >> "$LOG_FILE" 2>&1; then
        echo "[ERROR] Shutdown script failed. Instance will remain running." | tee -a "$LOG_FILE"
        exit 1
    fi

    exit 0
}

# -----------------------------------------------------------------------------
# Run scripts
# -----------------------------------------------------------------------------

# Step 1
echo "[INFO] Step 1: download_S3.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/download_S3.py > logs/bin_scripts/download_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 1: download_S3.py"
fi

# Step 2
echo "[INFO] Step 2: check_pipeline.sh" | tee -a "$LOG_FILE"
if ! bash bin/check_pipeline.sh > logs/bin_scripts/check_pipeline.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 2: check_pipeline.sh"
fi

# Step 3
echo "[INFO] Step 3: run_pipeline.sh" | tee -a "$LOG_FILE"
if ! bash bin/run_pipeline.sh > logs/bin_scripts/run_pipeline.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 3: run_pipeline.sh"
fi

# Step 4
echo "[INFO] Step 4: package_outputs.py" | tee -a "$LOG_FILE"
if ! python3 bin/package_outputs.py > logs/bin_scripts/package_outputs.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 4: package_outputs.py"
fi

# Step 5
echo "[INFO] Step 5: upload_S3.sh" | tee -a "$LOG_FILE"
if ! bash bin/upload_S3.sh > logs/bin_scripts/upload_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 5: upload_S3.sh"
fi

# ✅ Success case
handle_exit "SUCCEEDED" "Pipeline run completed successfully"


