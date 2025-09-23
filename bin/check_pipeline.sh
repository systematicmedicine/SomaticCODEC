#!/usr/bin/env bash

# Check that this script is being run from the project root
if [[ ! -f "config/config.yaml" || ! -f "Snakefile" ]]; then
  echo "[ERROR] Please run this script from the project root."
  exit 1
fi

# Run snakemake dryrun
snakemake \
    --configfile config/config.yaml
    --cores all \
    --dryrun
    2>&1 | tee logs/bin_scripts/check_pipeline_$(date +%Y%m%d).log