#!/usr/bin/env bash
# ==============================================================================
# run_pipeline.sh
#
# Runs the snakemake pipeline. Dynamically detects availiable system resources.
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

echo "[INFO] Starting run_pipeline.sh: $(date)"

# ------------------------------------------------------------------------------
# Dynamically detect availiable resources
# ------------------------------------------------------------------------------
# Memory
GLOBAL_BUFFER_GB=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['resources']['memory']['global_buffer'])
")
TOTAL_MEM_GB=$(awk '/MemTotal/ {printf "%.0f", $2 / 1024 / 1024}' /proc/meminfo)
USABLE_MEM_GB=$((TOTAL_MEM_GB - GLOBAL_BUFFER_GB))

echo "[INFO] Usable memory for Snakemake $(USABLE_MEM_GB) GB"

# CPU
GLOBAL_CORE_BUFFER=$(python3 -c "
import yaml
with open('config/config.yaml') as f:
    cfg = yaml.safe_load(f)
print(cfg['resources']['threads']['global_buffer'])
")

TOTAL_CORES=$(nproc)
USABLE_CORES=$((TOTAL_CORES - GLOBAL_CORE_BUFFER))
echo "[INFO] Usable cores for Snakemake: ${USABLE_CORES}"

# ------------------------------------------------------------------------------
# Run pipeline
# ------------------------------------------------------------------------------
snakemake \
    --snakefile Snakefile \
    --configfile config/config.yaml \
    --cores all \
    --resources memory=$USABLE_MEM_GB \
    --keep-going \
    --reason \
    --stats logs/bin_scripts/run_pipeline_stats.json
  
echo "[INFO] Finished run_pipeline.sh: $(date)"