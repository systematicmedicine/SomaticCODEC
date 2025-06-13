"""
--- download_S3toEC2.py ---

Downloads data from S3 to the local EC2 instance:
    * Downloads all data defined in /config/download_list.csv
    * Assumes that the EC2 instance running this script has permission to access the data

Authors:
    * Chat-GPT
    * Cameron Fraser
"""

import csv
import os
import subprocess
from pathlib import Path

# Always resolve paths relative to the project root
PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "config" / "download_list.csv"

with open(CSV_PATH, newline='') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        file_name = row["file_name"]
        source_dir = row["source_dir"].rstrip("/")
        destination_dir = row["destination_dir"].rstrip("/")

        source = f"{source_dir}/{file_name}"
        destination_path = PROJECT_ROOT / destination_dir / file_name

        # Ensure destination directory exists
        destination_path.parent.mkdir(parents=True, exist_ok=True)

        print(f"Downloading: {source} -> {destination_path}")
        result = subprocess.run(
            ["aws", "s3", "cp", source, str(destination_path)],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            print(f"❌ Failed to download {file_name}")
            print(result.stderr)
        else:
            print(f"✅ Downloaded {file_name}")