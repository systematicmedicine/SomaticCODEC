#!/usr/bin/env bash
# ==============================================================================
# check_pipeline.sh
#
# Checks the pipeline using Snakemake dryrun
#
# Authors:
#   - Cameron Fraser
#   - ChatGPT
# ==============================================================================
set -euo pipefail

# Check that this script is being run from the project root
if [[ ! -f "config/config.yaml" || ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

echo "[INFO] Starting check_pipeline.sh: $(date)"

# Run snakemake dryrun
snakemake \
    --configfile config/config.yaml \
    --cores all \
    --dryrun

echo "[INFO] Finished check_pipeline.sh: $(date)"