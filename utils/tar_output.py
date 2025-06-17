#!/usr/bin/env python3

"""
-- tar_output.py --

Create a tar file containing all key outputs of a successful pipeline run
    * /results
    * /metrics
    * /rules
    * /scripts
    * /config
    * Snakefile

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

# Files and directories to include in the archive
items_to_archive = [
    "results",
    "metrics",
    "rules",
    "scripts",
    "config",
    "Snakefile"
]

# Create the archive
with tarfile.open(archive_path, "w:gz") as tar:
    for item in items_to_archive:
        item_path = os.path.join(root_dir, item)
        tar.add(item_path, arcname=item)

print(f"Archive created at {archive_path}")