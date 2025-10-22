"""
--- write_git_metadata.py

Writes git metadata to a JSON file so that the version of the pipeline that was run can be eaisly identified

To be used exclusively with the Snakemake rule write_git_metadata

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import os
import subprocess
import json
from pathlib import Path

# Redirect stdout and stderr to log file
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting write_git_metadata.py")

# -- Ensure Git will accept /work as a safe repo (even with UID mismatch) --
# This must run before any Git commands
try:
    subprocess.run(["git", "config", "--global", "--add", "safe.directory", "/work"], check=False)
except Exception as e:
    print(f"Warning: failed to set safe.directory: {e}")

# -- Determine project root using Git --
def get_git_root():
    try:
        git_root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"]).decode().strip()

        # Ensure Git accepts the root as a safe directory
        subprocess.run(
            ["git", "config", "--global", "--add", "safe.directory", git_root],
            check=False,
        )
        return git_root
    except subprocess.CalledProcessError:
        raise RuntimeError("Not a Git repository or unsafe directory")

GIT_ROOT = get_git_root()

output_path = snakemake.output.file_path  # Snakemake-injected

def run_git_command(cmd):
    return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, cwd=GIT_ROOT).decode().strip()

def get_git_metadata():
    try:
        metadata = {
            "short_commit_hash": run_git_command(["git", "rev-parse", "--short", "HEAD"]),
            "full_commit_hash": run_git_command(["git", "rev-parse", "HEAD"]),
            "branch_name": run_git_command(["git", "rev-parse", "--abbrev-ref", "HEAD"]),
            "commit_date": run_git_command(["git", "show", "-s", "--format=%ci", "HEAD"]),
        }

        try:
            metadata["git_tag"] = run_git_command(["git", "describe", "--tags", "--exact-match"])
        except subprocess.CalledProcessError:
            metadata["git_tag"] = None

        return metadata
    except subprocess.CalledProcessError:
        raise RuntimeError("Git command failed")

# Write metadata to file
metadata = get_git_metadata()
Path(output_path).parent.mkdir(parents=True, exist_ok=True)
with open(output_path, "w") as f:
    json.dump(metadata, f, indent=4)

# Log completion
print("[INFO] Completed write_git_metadata.py")