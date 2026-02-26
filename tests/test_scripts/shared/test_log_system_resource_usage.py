"""
--- test_log_system_resource_usage.py

Tests the script log_system_resource_usage.sh

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import time
import os

def test_log_system_resource_usage(tmp_path):
    log_file = tmp_path / "system_resource_usage.csv"
    
    # Run the script in the background
    proc = subprocess.Popen(
        ["bash", "rule_scripts/shared/metrics/log_system_resource_usage.sh"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env={**os.environ, 
             "LOG_FILE": str(log_file), 
             "SLEEP_INTERVAL": "1",
             "TOTAL_CORES": "4"},
        text=True,
    )

    try:
        # Let run for 3 seconds
        time.sleep(3)
        
        # Kill the process
        proc.terminate()
        proc.wait(timeout=5)
    finally:
        # Ensure cleanup in case of errors
        proc.kill()

    # Read the log file
    with open(log_file) as f:
        lines = f.read().strip().splitlines()

    # Assertions
    assert lines[0] == "time,disk_used_GB,disk_avail_GB,disk_IOPS,disk_throughput_MiBs,mem_used_GB,mem_avail_GB,cpu_load,cpu_avail", "Header missing or malformed"
    assert len(lines) >= 2, "No data lines written"
