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
echo "time,disk_used_GB,disk_avail_GB,mem_used_GB,mem_avail_GB,cpu_load,cpu_avail" > logs/pipeline/system_resource_usage.csv
(
    while true; do
        now=$(date +"%Y-%m-%d %H:%M:%S")

        disk_used_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$3); print $3}')
        disk_avail_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$4); print $4}')

        mem_used_GB=$(free -g | awk '/Mem:/ {print $3}')
        mem_avail_GB=$(free -g | awk '/Mem:/ {print $7}')

        cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
        cpu_avail=$(($(nproc) - ${cpu_load%.*}))

        echo "$now,$disk_used_GB,$disk_avail_GB,$mem_used_GB,$mem_avail_GB,$cpu_load,$cpu_avail" >> logs/pipeline/system_resource_usage.csv
        sleep 60
    done
) &
MONITOR_RESOURCES_PROCESS_ID=$!

# Stop background monitoring when script exits (finishes or errors)
trap "kill $MONITOR_RESOURCES_PROCESS_ID" EXIT

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
