#!/usr/bin/env bash
#
# --- run_pipeline.sh ---
#
# Snakemake command to run the codec-opensource pipeline
#
# Capturing this command in a file improves tracability and reproducibility between runs
#
# Authors: 
#   - Cameron Fraser
#   - Joshua Johnstone
#

set -e

# Create directory for pipeline logs
mkdir -p logs/pipeline

# Start continuous resource monitoring in the background
MONITOR_RESOURCES_PID=$(./monitor_system_resources.sh)

# Stop background resource monitoring when pipeline finishes or crashes
trap "kill $MONITOR_RESOURCES_PID" EXIT

# Run Snakemake
snakemake \
    --snakefile Snakefile \
    --configfile config/config.yaml \
    --cores all \
    --resources memory=370 \
    --notemp \
    --keep-going \
    --reason \
    --stats logs/pipeline/pipeline_stats.json \
    2>&1 | tee logs/pipeline/pipeline_run_$(date +%Y%m%d).log
