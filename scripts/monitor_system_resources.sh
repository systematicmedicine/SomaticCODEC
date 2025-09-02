#!/usr/bin/env bash
#
# --- monitor_system_resources.sh ---
#
# Logs disk space, memory, and cpu load at a defined interval while pipeline is running.
#
# Authors: 
#   - Joshua Johnstone
#   - Chat-GPT
#
set -e

# Define log file path
LOG_FILE="${LOG_FILE:-logs/pipeline/system_resource_usage.csv}"

# Ensure log file directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Define interval between logs
SLEEP_INTERVAL="${SLEEP_INTERVAL:-60}"

# Write header if file does not exist
echo "time,disk_used_GB,disk_avail_GB,mem_used_GB,mem_avail_GB,cpu_load,cpu_avail" > "$LOG_FILE"
(
    while true; do
        now=$(date +"%Y-%m-%d %H:%M:%S")

        disk_used_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$3); print $3}')
        disk_avail_GB=$(df -BG / | tail -1 | awk '{gsub("G","",$4); print $4}')

        mem_used_GB=$(free -g | awk '/Mem:/ {print $3}')
        mem_avail_GB=$(free -g | awk '/Mem:/ {print $7}')

        cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)
        cpu_avail=$(($(nproc) - ${cpu_load%.*}))

        echo "$now,$disk_used_GB,$disk_avail_GB,$mem_used_GB,$mem_avail_GB,$cpu_load,$cpu_avail" >> "$LOG_FILE"
        sleep "$SLEEP_INTERVAL"
    done
) &
MONITOR_RESOURCES_PID=$!

# Export the process ID so the caller can trap and kill it
echo "$MONITOR_RESOURCES_PID"
