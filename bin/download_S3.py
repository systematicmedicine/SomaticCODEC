"""
--- download_S3.py ---

Downloads data from S3 to the local EC2 instance:
    - Downloads all data defined in /config/download_list.csv
    - Assumes that the EC2 instance running this script has permission to access the data

Authors:
    - Cameron Fraser

"""

print("[INFO] Starting download_s3.py")

import csv
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "config" / "download_list.csv"

failed = False

with open(CSV_PATH, newline='', encoding='utf-8-sig') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        file_name = row["file_name"]
        source = row["source_dir"].rstrip("/") + "/" + file_name
        destination_dir = PROJECT_ROOT / row["destination_dir"].rstrip("/")
        destination_path = destination_dir / file_name
        expected_md5sum = row["expected_md5sum"]

        destination_dir.mkdir(parents=True, exist_ok=True)

        print(f"Downloading: {source} -> {destination_path}")
        result = subprocess.run(
            ["aws", "s3", "cp", source, str(destination_path)],
            capture_output=True, text=True
        )

        if result.returncode != 0:
            failed = True
            print(f"❌ Failed to download {file_name}")
            print(result.stderr)
            continue
        else:
            print(f"✅ Downloaded {file_name}")

        downloaded_md5sum = subprocess.run(
            ["md5sum", str(destination_path)],
            capture_output=True, text=True, check=True
        ).stdout.split()[0].strip()

        if downloaded_md5sum != expected_md5sum:
            failed = True
            print(f"❌ md5sum of {file_name} does not match expected md5sum")
            print(f"expected: {expected_md5sum}")
            print(f"got: {downloaded_md5sum}")
        else:
            print(f"✅ md5sum of {file_name} matches expected md5sum")

if failed:
    exit(1)

print("[INFO] download_s3.py complete")
