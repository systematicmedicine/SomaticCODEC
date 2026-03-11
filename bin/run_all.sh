#!/usr/bin/env bash
#
# --- run_all.sh ---
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
#

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
print(cfg['infrastructure']['aws']['sns_arn'])
")

EXPERIMENT_NAME=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['run_name'])
")

# Ensure required environment variables are set
: "${AWS_REGION:?AWS_REGION must be set}"
: "${INSTANCE_ID:?INSTANCE_ID must be set}"

# -----------------------------------------------------------------------------
# Cleanup function
# -----------------------------------------------------------------------------
function handle_exit {
    local STATUS=$1
    local MSG=$2

    # Log exit message
    echo "[INFO] $MSG" | tee -a "$LOG_FILE"

    # Message via SNS
    aws sns publish \
        --topic-arn "$SNS_ARN" \
        --subject "Pipeline $EXPERIMENT_NAME $STATUS" \
        --message "$MSG" \
        --region $AWS_REGION

    # Wait 2 miutes before shutting down
    echo "[INFO] Instance shutdown in 2 minutes" | tee -a "$LOG_FILE"
    sleep 120

    # Request shutdown
    echo "[INFO] Triggering EC2 shutdown..." | tee -a "$LOG_FILE"
    if ! bash bin/shutdown_instance.sh >> "$LOG_FILE" 2>&1; then
        echo "[ERROR] Shutdown script failed. Instance will remain running." | tee -a "$LOG_FILE"
        exit 1
    fi

    if [ "$STATUS" = "FAILED" ]; then
        exit 1
    else
        exit 0
    fi
}

# -----------------------------------------------------------------------------
# Run scripts
# -----------------------------------------------------------------------------

# Step 1: check_sample_metadata.py
echo "[INFO] Step 1: check_sample_metadata.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/check_sample_metadata.py > logs/bin_scripts/check_sample_metadata.py 2>&1; then
    echo "[ERROR] check_sample_metadata.py failed. See logs/bin_scripts/check_sample_metadata.py" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 2: check_download_list_S3.py
echo "[INFO] Step 1: check_download_list_S3.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/check_download_list_S3.py > logs/bin_scripts/check_download_list_S3.py 2>&1; then
    echo "[ERROR] check_download_list_S3.py failed. See logs/bin_scripts/check_download_list_S3.py" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 3: download_S3.py
echo "[INFO] Step 2: download_S3.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/download_S3.py > logs/bin_scripts/download_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 2: download_S3.py"
fi

# Step 4: dryrun.sh
echo "[INFO] Step 2: dryrun.sh" | tee -a "$LOG_FILE"
if ! bash bin/dryrun.sh > logs/bin_scripts/dryrun.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 2: dryrun.sh"
fi

# Step 5: run_pipeline.sh
echo "[INFO] Step 4: run_pipeline.sh" | tee -a "$LOG_FILE"
if ! bash bin/run_pipeline.sh > logs/bin_scripts/run_pipeline.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 4: run_pipeline.sh"
fi

# Step 6: package_outputs.py
echo "[INFO] Step 5: package_outputs.py" | tee -a "$LOG_FILE"
if ! python3 bin/package_outputs.py > logs/bin_scripts/package_outputs.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 5: package_outputs.py"
fi

# Step 7: upload_S3.sh
echo "[INFO] Step 6: upload_S3.sh" | tee -a "$LOG_FILE"
if ! bash bin/upload_S3.sh > logs/bin_scripts/upload_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 6: upload_S3.sh"
fi

# ✅ Success case
handle_exit "SUCCEEDED" "Pipeline run completed successfully"


