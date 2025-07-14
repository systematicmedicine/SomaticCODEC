#!/usr/bin/env python3

"""
-- tar_output.py --

Create a tar file containing all key outputs of a successful pipeline run,
structured as follows inside the archive:
    * /data/results
    * /data/metrics
    * /methods/rules
    * /methods/scripts
    * /methods/config
    * /methods/Snakefile

Authors:
    * Chat-GPT
    * Cameron Fraser
"""

import os
import tarfile
import yaml

# Get absolute path to the project root (one level above /utils)
root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Load experiment_name from config/config.yaml
config_path = os.path.join(root_dir, "config", "config.yaml")
with open(config_path, "r") as f:
    config = yaml.safe_load(f)
experiment_name = config["experiment_name"]

# Define archive path
archive_path = os.path.join(root_dir, f"{experiment_name}.tar.gz")

# Mapping of source path to target path inside archive
archive_structure = {
    "results": "Data/results",
    "metrics": "Data/metrics",
    "logs": "Data/logs",
    "rules": "Methods/rules",
    "scripts": "Methods/scripts",
    "config": "Methods/config",
    "Snakefile": "Methods/Snakefile",
    "run_pipeline.sh" : "Methods/run_pipeline.sh"
}

# Create the archive
with tarfile.open(archive_path, "w:gz") as tar:
    for src, dest in archive_structure.items():
        src_path = os.path.join(root_dir, src)
        tar.add(src_path, arcname=dest)

print(f"Archive created at {archive_path}")