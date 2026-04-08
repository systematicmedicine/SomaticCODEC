"""
--- build_test_config.py ---

Builds the test runtime config using bin/create_runtime_config.py

Authors:
    - Joshua Johnstone

"""

import subprocess
from pathlib import Path
import sys

def build_test_config(project_root, test_config_path):

    CREATE_RUNTIME_CONFIG_SCRIPT = "bin/create_runtime_config.py"

    cmd = ["python3", CREATE_RUNTIME_CONFIG_SCRIPT,
           "--environment", "test",
           "--profile", "test"]
    subprocess.run(
        cmd,
        cwd=str(project_root),
        text=True,
        check = True)
    
    if not Path(test_config_path).is_file():
        sys.exit(f"[ERROR] Test runtime config ({test_config_path}) not found")
    
    return 0