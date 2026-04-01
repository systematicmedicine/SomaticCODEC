#!/usr/bin/env bash
#
# --- run_all.sh ---
#
# Master orchestration script to run the full bioinformatics pipeline:
#   1. Create runtime config (combine environment and profile configs)
#   2. Check sample metadata configuration
#   3. Check download list configuration
#   4. Download files from S3
#   5. Check pipeline configuration (Snakemake dryrun)
#   6. Run pipeline
#   7. Package outputs for upload to S3
#   8. Upload packaged outputs to S3
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
#   - Joshua Johnstone
#

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

set -euo pipefail

# Define log
LOG_FILE="logs/bin_scripts/run_all.log"
mkdir -p "$(dirname "$LOG_FILE")"
echo "[INFO] Starting run_all.sh: $(date)" | tee -a "$LOG_FILE"

# Ensure required environment variables are set
: "${AWS_REGION:?AWS_REGION must be set}"
: "${INSTANCE_ID:?INSTANCE_ID must be set}"
: "${ENVIRONMENT:?ENVIRONMENT must be set (name of the environment directory under environments/)}"
: "${PROFILE:?PROFILE must be set (name of the profile directory under profiles/)}"
: "${S3_TARGET_DIR:?S3_TARGET_DIR must be set ("s3://<bucket>/<dir>")}"
: "${SNS_ARN:?SNS_ARN must be set ("arn:aws:sns:<region>:<account_ID>:<topic_name>")}"

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
        --subject "Pipeline $STATUS" \
        --message "$MSG" \
        --region $AWS_REGION

    # Wait 2 minutes before shutting down
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

# Step 1: create_runtime_config.py
echo "[INFO] Step 1: create_runtime_config.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/create_runtime_config.py --environment "$ENVIRONMENT" --profile "$PROFILE" > logs/bin_scripts/create_runtime_config.log 2>&1; then
    echo "[ERROR] create_runtime_config.py failed. See logs/bin_scripts/create_runtime_config.log" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 2: check_sample_metadata.py
echo "[INFO] Step 2: check_sample_metadata.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/check_sample_metadata.py > logs/bin_scripts/check_sample_metadata.log 2>&1; then
    echo "[ERROR] check_sample_metadata.py failed. See logs/bin_scripts/check_sample_metadata.log" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 3: check_download_list_S3.py
echo "[INFO] Step 3: check_download_list_S3.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/check_download_list_S3.py > logs/bin_scripts/check_download_list_S3.log 2>&1; then
    echo "[ERROR] check_download_list_S3.py failed. See logs/bin_scripts/check_download_list_S3.log" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 4: download_S3.py
echo "[INFO] Step 4: download_S3.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/download_S3.py > logs/bin_scripts/download_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 4: download_S3.py"
fi

# Step 5: dryrun.sh
echo "[INFO] Step 5: dryrun.sh" | tee -a "$LOG_FILE"
if ! bash bin/dryrun.sh > logs/bin_scripts/dryrun.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 5: dryrun.sh"
fi

# Step 6: run_pipeline.py
echo "[INFO] Step 6: run_pipeline.py" | tee -a "$LOG_FILE"
if ! python3 -u bin/run_pipeline.py > logs/bin_scripts/run_pipeline.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 6: run_pipeline.py"
fi

# Step 7: package_outputs.py
echo "[INFO] Step 7: package_outputs.py" | tee -a "$LOG_FILE"
if ! python3 bin/package_outputs.py > logs/bin_scripts/package_outputs.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 7: package_outputs.py"
fi

# Step 8: upload_S3.sh
echo "[INFO] Step 8: upload_S3.sh" | tee -a "$LOG_FILE"
if ! S3_TARGET_DIR="$S3_TARGET_DIR" bash bin/upload_S3.sh > logs/bin_scripts/upload_S3.log 2>&1; then
    handle_exit "FAILED" "Pipeline failed at step 8: upload_S3.sh"
fi

# ✅ Success case
handle_exit "SUCCEEDED" "Pipeline run completed successfully"
