#!/usr/bin/env python3

"""
-- package_outputs.py --

Create a tar file containing all key outputs of a successful pipeline run.

Authors:
    * Chat-GPT
    * Cameron Fraser
"""

import os
import sys
import tarfile
import yaml

def main():
    print("[INFO] Starting package_outputs.py")

    # Resolve project root
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    print(f"[INFO] Project root: {root_dir}")

    # Load experiment name from config
    try:
        config_path = os.path.join(root_dir, "config", "config.yaml")
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
        experiment_name = config["experiment"]["name"]
        print(f"[INFO] Experiment name: {experiment_name}")
    except Exception as e:
        print(f"[ERROR] Failed to read experiment name from config: {e}")
        sys.exit(1)

    # Define output archive path
    archive_path = os.path.join(root_dir, f"{experiment_name}.tar.gz")
    print(f"[INFO] Creating archive: {archive_path}")

    # Define structure to add to archive
    archive_structure = {
        "results": "Data/results",
        "metrics": "Data/metrics",
        "logs": "Data/logs",
        "rules": "Methods/rules",
        "scripts": "Methods/scripts",
        "config": "Methods/config",
        "Snakefile": "Methods/Snakefile",
        "bin" : "Methods/bin",
        "helpers" : "Methods/helpers",
        "Dockerfile" : "Methods/Dockerfile",
        "environment.yml" : "Methods/environment.yml"
    }

    try:
        with tarfile.open(archive_path, "w:gz") as tar:
            for src, dest in archive_structure.items():
                src_path = os.path.join(root_dir, src)
                if not os.path.exists(src_path):
                    print(f"[WARN] Skipping missing path: {src_path}")
                    continue
                print(f"[INFO] Adding: {src_path} → {dest}")
                tar.add(src_path, arcname=dest)
    except Exception as e:
        print(f"[ERROR] Failed to create archive: {e}")
        sys.exit(1)

    print(f"[INFO] Archive successfully created at: {archive_path}")
    print("[INFO] Finished package_outputs.py")

if __name__ == "__main__":
    main()
