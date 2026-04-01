#!/usr/bin/env python3

"""
-- package_outputs.py --

Create a tar file containing all key outputs of a successful pipeline run,
including a checksums.txt file for integrity verification.

Authors:
    * Cameron Fraser
"""

import os
import sys
import tarfile
import hashlib
import tempfile
from datetime import datetime

def compute_file_checksum(file_path, hash_algo="sha256"):
    """Compute SHA256 checksum of a file."""
    h = hashlib.new(hash_algo)
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def collect_checksums(root_dir, archive_structure):
    """Walk through all files in the archive structure and compute checksums."""
    print("[INFO] Computing file checksums...")
    checksum_lines = []

    for src, _ in archive_structure.items():
        src_path = os.path.join(root_dir, src)
        if not os.path.exists(src_path):
            print(f"[WARN] Skipping checksum for missing path: {src_path}")
            continue

        if os.path.isfile(src_path):
            rel_path = os.path.relpath(src_path, root_dir)
            checksum = compute_file_checksum(src_path)
            checksum_lines.append(f"{checksum}  {rel_path}")
        else:
            for dirpath, _, filenames in os.walk(src_path):
                for filename in filenames:
                    file_path = os.path.join(dirpath, filename)
                    rel_path = os.path.relpath(file_path, root_dir)
                    checksum = compute_file_checksum(file_path)
                    checksum_lines.append(f"{checksum}  {rel_path}")

    # Write checksums.txt to a temporary directory
    tmp_dir = tempfile.mkdtemp()
    tmp_checksum_path = os.path.join(tmp_dir, "checksums.txt")
    with open(tmp_checksum_path, "w") as f:
        f.write("\n".join(sorted(checksum_lines)) + "\n")

    print(f"[INFO] Checksums written to temporary file: {tmp_checksum_path}")
    return tmp_checksum_path

def main():
    print("[INFO] Starting package_outputs.py")

    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    print(f"[INFO] Project root: {root_dir}")

    timestamp = datetime.now().strftime("%Y%m%d")
    archive_path = os.path.join(root_dir, f"run_{timestamp}.tar.gz")
    print(f"[INFO] Creating archive: {archive_path}")

    archive_structure = {
        "results": "Processed data/results",
        "metrics": "Processed data/metrics",
        "logs": "Processed data/logs",
        "rules": "Methods/rules",
        "rule_scripts": "Methods/rule_scripts",
        "environments": "Methods/environments",
        "profiles": "Methods/profiles",
        "tmp/runtime_config/merged_config.yaml": "Methods/merged_config.yaml",
        "experiment": "Methods/experiment",
        "Snakefile": "Methods/Snakefile",
        "bin": "Methods/bin",
        "helpers": "Methods/helpers",
        "Dockerfile": "Methods/Dockerfile",
        "environment.yml": "Methods/environment.yml"
    }

    # Compute checksums
    try:
        checksum_file = collect_checksums(root_dir, archive_structure)
    except Exception as e:
        print(f"[ERROR] Failed to compute checksums: {e}")
        sys.exit(1)

    # Package everything into tar.gz
    try:
        with tarfile.open(archive_path, "w:gz") as tar:
            for src, dest in archive_structure.items():
                src_path = os.path.join(root_dir, src)
                if not os.path.exists(src_path):
                    print(f"[WARN] Skipping missing path: {src_path}")
                    continue
                print(f"[INFO] Adding: {src_path} → {dest}")
                tar.add(src_path, arcname=dest)

            # Add checksums.txt to archive under Processed data/checksums/
            print(f"[INFO] Adding: {checksum_file} → Processed data/checksums/checksums.txt")
            tar.add(checksum_file, arcname="Processed data/checksums/checksums.txt")

    except Exception as e:
        print(f"[ERROR] Failed to create archive: {e}")
        sys.exit(1)

    print(f"[INFO] Archive successfully created at: {archive_path}")
    print("[INFO] Finished package_outputs.py")

if __name__ == "__main__":
    main()
