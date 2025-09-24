"""
--- test_monitor_system_resources.py

Tests the script monitor_system_resources.sh

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import time
import os
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

def test_monitor_resources(tmp_path):
    log_file = tmp_path / "system_resource_usage.csv"
    
    # Run the script in the background
    proc = subprocess.Popen(
        ["bash", "bin/monitor_system_resources.sh"],
        cwd=project_root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env={**os.environ, "LOG_FILE": str(log_file), "SLEEP_INTERVAL": "1"},
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
    assert lines[0] == "time,disk_used_GB,disk_avail_GB,mem_used_GB,mem_avail_GB,cpu_load,cpu_avail", "Header missing or malformed"
    assert len(lines) >= 2, "No data lines written"
