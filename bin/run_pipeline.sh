#!/usr/bin/env bash

# Check that this script is being run from the project root
if [[ ! -f "config/config.yaml" || ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

# Run pipeline
snakemake \
    --snakefile Snakefile \
    --configfile config/config.yaml \
    --cores all \
    --resources memory=490 \
    --keep-going \
    --reason \
    --stats logs/bin_scripts/run_pipeline_stats_$(date +%Y%m%d).json \
    &> | tee logs/bin_scripts/run_pipeline_$(date +%Y%m%d).log