#!/usr/bin/env bash
#
# --- dryrun.sh ---
#
# Checks the pipeline using Snakemake dryrun
#
# Authors:
#   - Cameron Fraser
#

set -euo pipefail

# Check that this script is being run from the project root
if [[ ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

RUNTIME_CONFIG="tmp/runtime_config/merged_config.yaml"

# Check runtime config exists
if [[ ! -f "$RUNTIME_CONFIG" ]]; then
  echo "[ERROR] Runtime config not found at $RUNTIME_CONFIG"
  echo "[ERROR] Please run bin/create_runtime_config.py first."
  exit 1
fi

echo "[INFO] Starting dryrun.sh: $(date)"
echo "[INFO] Using config: $RUNTIME_CONFIG"

# Run snakemake dryrun
snakemake \
    --snakefile Snakefile \
    --configfile "$RUNTIME_CONFIG" \
    --cores all \
    --dryrun

echo "[INFO] Finished dryrun.sh: $(date)"