#!/usr/bin/env python3
"""
--- run_pipeline.py ---

Runs the Snakemake pipeline. Dynamically detects available system resources.

Requires the runtime config to already exist at:
    tmp/runtime_config/merged_config.yaml

Authors:
    - Cameron Fraser
    - Joshua Johnstone
"""

# ------------------------------------------------------------------------------------------
# Imports
# ------------------------------------------------------------------------------------------
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
import yaml
import argparse

# ------------------------------------------------------------------------------------------
# Bootstrap helpers
# ------------------------------------------------------------------------------------------
def find_project_root(start: Path) -> Path:
    start = start.resolve()
    for p in [start, *start.parents]:
        if (
            (p / "profiles").is_dir()
            and (p / "environments").is_dir()
            and (p / "helpers").is_dir()
            and (p / "rule_scripts").is_dir()
            and (p / "Snakefile").is_file()
        ):
            return p
    raise RuntimeError(
        "Could not find repo root (profiles/, environments/, helpers/, rule_scripts/, Snakefile)."
    )

PROJECT_ROOT = find_project_root(Path(__file__))

# ------------------------------------------------------------------------------------------
# Config helpers
# ------------------------------------------------------------------------------------------
def load_runtime_config(config_path: Path) -> dict:
    if not config_path.is_file():
        raise RuntimeError(
            f"Runtime config not found: {config_path}\n"
            "Please run bin/create_runtime_config.py first."
        )

    with config_path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

# ------------------------------------------------------------------------------------------
# Resource detection
# ------------------------------------------------------------------------------------------
def get_total_memory_gb() -> int:
    meminfo_path = Path("/proc/meminfo")
    if not meminfo_path.is_file():
        raise RuntimeError("Could not read /proc/meminfo to determine system memory.")

    with meminfo_path.open("r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                parts = line.split()
                mem_kb = int(parts[1])
                return round(mem_kb / 1024 / 1024)

    raise RuntimeError("Could not determine total system memory from /proc/meminfo.")

def get_total_cores() -> int:
    total_cores = os.cpu_count()
    if total_cores is None:
        raise RuntimeError("Could not determine CPU core count.")
    return total_cores

# ------------------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the Snakemake pipeline"
    )
    parser.add_argument(
        "--notemp",
        action="store_true",
        help="Run Snakemake in notemp mode",
    )
    return parser.parse_args()

# ------------------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------------------
def main() -> int:
    print(f"[INFO] Starting run_pipeline.py: {datetime.now()}")

    args = parse_args()

    runtime_config_path = PROJECT_ROOT / "tmp" / "runtime_config" / "merged_config.yaml"
    config_data = load_runtime_config(runtime_config_path)

    try:
        global_memory_buffer = config_data["infrastructure"]["memory"]["global_buffer"]
        global_threads_buffer = config_data["infrastructure"]["threads"]["global_buffer"]
    except KeyError as e:
        raise RuntimeError(f"Missing required infrastructure config key: {e}") from e

    total_mem_gb = get_total_memory_gb()
    usable_mem_gb = total_mem_gb - global_memory_buffer
    if usable_mem_gb <= 0:
        raise RuntimeError(
            f"Computed usable memory is invalid: {usable_mem_gb} GB "
            f"(total={total_mem_gb}, global_buffer={global_memory_buffer})."
        )
    print(f"[INFO] Usable memory for Snakemake: {usable_mem_gb} GB")

    total_cores = get_total_cores()
    usable_cores = total_cores - global_threads_buffer
    if usable_cores <= 0:
        raise RuntimeError(
            f"Computed usable cores is invalid: {usable_cores} "
            f"(total={total_cores}, global_buffer={global_threads_buffer})."
        )
    print(f"[INFO] Using runtime config: {runtime_config_path}")
    print(f"[INFO] Usable cores for Snakemake: {usable_cores}")

    log_dir = PROJECT_ROOT / "logs" / "bin_scripts"
    log_dir.mkdir(parents=True, exist_ok=True)
    stats_path = log_dir / "run_pipeline_stats.json"

    if args.notemp:
        # Run in notemp mode if flag is set to True
        snakemake_cmd = [
            "snakemake",
            "--snakefile", str(PROJECT_ROOT / "Snakefile"),
            "--configfile", str(runtime_config_path),
            "--cores", str(usable_cores),
            "--resources", f"memory={usable_mem_gb}",
            "--keep-going",
            "--stats", str(stats_path),
            "--notemp",
    ]     
    else: 
        snakemake_cmd = [
            "snakemake",
            "--snakefile", str(PROJECT_ROOT / "Snakefile"),
            "--configfile", str(runtime_config_path),
            "--cores", str(usable_cores),
            "--resources", f"memory={usable_mem_gb}",
            "--keep-going",
            "--stats", str(stats_path),
        ]

    result = subprocess.run(
        snakemake_cmd,
        cwd=str(PROJECT_ROOT),
        check=False,
    )

    print(f"[INFO] Finished run_pipeline.py: {datetime.now()}")
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())