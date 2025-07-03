#!/usr/bin/env bash
#
# --- run_pipeline.sh ---
#
# Snakemake command to run the codec-opensource pipeline
#
# Capturing this command in a file improves tracability and reproducibility between runs
#
# Author: Cameron Fraser
# Date: 27-Jun-2025
#

snakemake \
    --snakefile Snakefile_dev_CF \
    --configfile config/config.yaml \
    --cores all \
    --resources mem=370 \
    --notemp \
    --keep-going \
    --verbose \
    --reason \
    --stats metrics/pipeline_stats.json \
    2>&1 | tee metrics/snakemake.log
