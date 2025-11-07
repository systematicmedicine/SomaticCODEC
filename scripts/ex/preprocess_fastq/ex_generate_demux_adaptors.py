#!/usr/bin/env python3
"""
--- ex_generate_demux_adaptors.py

Generate per-lane codec index adapter FASTA files for demultiplexing

To be used exclusively with rule ex_generate_demux_adaptors

Inputs:
  - Sample metadata (loaded via get_metadata.py)

Outputs:
  - FASTA files with only adapters used in the ex_sample column (no generic Quadruplex labels)

Author:
    - Chat GPT
    - Cameron Fraser
"""

# Import libraries
import sys
from pathlib import Path
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("--adapter_fasta_outputs", required=True, nargs="+")
parser.add_argument("--config", required=True)
parser.add_argument("--log", required=True)
args = parser.parse_args()

PROJECT_ROOT = Path(__file__).resolve().parents[1]  # assumes scripts/ is directly under PROJECT_ROOT
sys.path.insert(0, str(PROJECT_ROOT))
import helpers.get_metadata as md

# Redirect stderr and stdout to Snakemake log
sys.stdout = open(args.log, "a")
sys.stderr = open(args.log, "a")
print("[INFO] Starting ex_generate_demux_adaptors.py")

# Load config
config = json.loads(args.config)

# Load nested dictionary of ex adapter sequences
  # Assumes format: dict[ex_lane][ex_sample or ex_technical_control][region] -> adapter sequence (str)
adapter_dict = md.get_ex_lane_adapter_dict(config)

# Define output paths
output_paths = args.adapter_fasta_outputs

# Generate adapta FASTAS
for output_path in output_paths:
    output_path = Path(output_path)
    filename = output_path.name
    lane, region_with_ext = filename.split("_", 1)
    region = region_with_ext.replace(".fasta", "")
    sample_dict = adapter_dict.get(lane, {})
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        for sample_id, region_dict in sample_dict.items():
            sequence = region_dict[region]
            f.write(f">{sample_id}\n{sequence}\n")
    print(f"[INFO] Wrote: {output_path}")

print("[INFO] Finished ex_generate_demux_adaptors.py")