#!/usr/bin/env python3
"""
--- ex_generate_demux_adaptors.py ---

Generate a single per-lane codec index adapter FASTA file for demultiplexing.

To be used with the wildcarded Snakemake rule ex_generate_demux_adaptors:
  output: tmp/{ex_lane}/{ex_lane}_{region}.fasta

Inputs:
  --adapter_dict : JSON string with structure
      dict[ex_lane][ex_sample or ex_technical_control][region] -> adapter sequence
  --lane         : lane ID (must match keys in adapter_dict)
  --region       : one of r1_start, r1_end, r2_start, r2_end
  --output       : output FASTA path
  --log          : log file path (stdout/stderr appended)

Outputs:
  - FASTA file at --output containing only adapters for samples/controls in the lane:
      >sample_id
      SEQUENCE

Author:
  - ChatGPT
  - Cameron Fraser
"""

import sys
import json
import argparse
from pathlib import Path

# -------------------------------------------------------------------------------------------
# Setup
# -------------------------------------------------------------------------------------------

p = argparse.ArgumentParser(description="Generate one demux adapter FASTA for a lane/region.")
p.add_argument("--adapter_dict", required=True, help="JSON: dict[lane][sample][region] -> sequence")
p.add_argument("--lane", required=True, help="Lane ID (e.g. LN_001)")
p.add_argument("--region", required=True, help="Region (e.g. r1_start)")
p.add_argument("--output", required=True, help="Output FASTA path")
p.add_argument("--log", required=True, help="Log path (stdout/stderr appended)")
args = p.parse_args()

# Redirect stderr and stdout to Snakemake log
sys.stdout = open(args.log, "a")
sys.stderr = open(args.log, "a")
print("[INFO] Starting ex_generate_demux_adaptors.py")
print(f"[INFO]   lane={args.lane} region={args.region} output={args.output}")

# -------------------------------------------------------------------------------------------
# Load & validate inputs
# -------------------------------------------------------------------------------------------

try:
    adapter_dict = json.loads(args.adapter_dict)
except json.JSONDecodeError as e:
    raise ValueError(f"adapter_dict is not valid JSON: {e}") from e

if not isinstance(adapter_dict, dict) or not adapter_dict:
    raise ValueError("adapter_dict is empty or not a JSON object")

lane = args.lane
region = args.region
out_fasta = Path(args.output)

if lane not in adapter_dict:
    available = ", ".join(sorted(adapter_dict.keys())[:10])
    suffix = " ..." if len(adapter_dict.keys()) > 10 else ""
    raise KeyError(f"Lane '{lane}' not found in adapter_dict. Available: {available}{suffix}")

sample_dict = adapter_dict[lane]
if not isinstance(sample_dict, dict) or not sample_dict:
    raise ValueError(f"Lane '{lane}' has no samples/controls in adapter_dict")

# Validate region exists for at least the first sample (fail early with a helpful message)
first_sample_id = next(iter(sample_dict.keys()))
first_regions = sample_dict[first_sample_id].keys()
if region not in first_regions:
    raise KeyError(
        f"Region '{region}' not present for lane '{lane}' (sample '{first_sample_id}'). "
        f"Available regions: {', '.join(sorted(first_regions))}"
    )

# Ensure output directory exists
out_fasta.parent.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------------------------------------
# Write FASTA
# -------------------------------------------------------------------------------------------

records = 0
with open(out_fasta, "w") as f:
    for sample_id in sorted(sample_dict.keys()):
        region_dict = sample_dict[sample_id]
        if region not in region_dict:
            raise KeyError(
                f"Missing region '{region}' for lane '{lane}', sample '{sample_id}'"
            )
        seq = region_dict[region]
        f.write(f">{sample_id}\n{seq}\n")
        records += 1

if records == 0:
    raise ValueError(f"Wrote 0 records to {out_fasta} for lane '{lane}', region '{region}'")

print(f"[INFO] Wrote: {out_fasta} ({records} records)")
print("[INFO] Finished ex_generate_demux_adaptors.py")
