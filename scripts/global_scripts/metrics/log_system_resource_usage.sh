#!/usr/bin/env bash
#
# --- log_system_resource_usage.sh ---
#
# Logs system resources at a defined interval while pipeline is running.
#
# Authors: 
#   - Joshua Johnstone
#   - Chat-GPT
#
set -e

# Define parameters
LOG_FILE="${LOG_FILE:-logs/global_rules/system_resource_usage.csv}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-60}"
TOTAL_CORES="${TOTAL_CORES:?TOTAL_CORES must be set}"

# Write header
echo "time,disk_used_GB,disk_avail_GB,disk_IOPS,disk_throughput_MiBs,mem_used_GB,mem_avail_GB,cpu_load,cpu_avail" > "$LOG_FILE"

while true; do
    
    disk_used_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$3); print $3}')
    disk_avail_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$4); print $4}')

    read disk_IOPS disk_throughput_MiBs <<< "$(
    iostat -dx 1 1 | awk '
        /^[a-z]/ {sum_i+=$2+$8; sum_t+=$3/1024+$9/1024}
        END {printf "%.2f %.2f", sum_i, sum_t}')"

    mem_used_GB=$(free -g | awk '/Mem:/ {print $3}')
    mem_avail_GB=$(free -g | awk '/Mem:/ {print $7}')

    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
    cpu_avail=$((TOTAL_CORES - ${cpu_load%.*}))

    now=$(date +"%Y-%m-%d %H:%M:%S")

    echo "$now,$disk_used_GB,$disk_avail_GB,$disk_IOPS,$disk_throughput_MiBs,$mem_used_GB,$mem_avail_GB,$cpu_load,$cpu_avail" >> "$LOG_FILE"
    sleep "$SLEEP_INTERVAL"
done
