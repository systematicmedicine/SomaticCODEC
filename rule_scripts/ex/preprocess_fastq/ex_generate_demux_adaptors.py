#!/usr/bin/env python3
"""
--- ex_generate_demux_adaptors.py ---

Generate per-lane codec index adapter FASTA files for demultiplexing.

To be used with the (non-wildcarded-by-region) Snakemake rule ex_generate_demux_adaptors:
  output:
    r1_start: tmp/{ex_lane}/{ex_lane}_r1_start.fasta
    r2_start: tmp/{ex_lane}/{ex_lane}_r2_start.fasta

Inputs:
  --adapter_dict : JSON string with structure
      dict[ex_lane][ex_sample][region] -> adapter sequence
  --lane         : lane ID (must match keys in adapter_dict)
  --r1_start     : output FASTA path for r1_start
  --r2_start     : output FASTA path for r2_start
  --log          : log file path (stdout/stderr appended)

Outputs:
  - FASTA files at --r1_start and --r2_start containing only adapters for samples/controls in the lane:
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

p = argparse.ArgumentParser(description="Generate demux adapter FASTAs (r1_start, r2_start) for a lane.")
p.add_argument("--adapter_dict", required=True, help="JSON: dict[lane][sample][region] -> sequence")
p.add_argument("--lane", required=True, help="Lane ID (e.g. LN_001)")
p.add_argument("--r1_start", required=True, help="Output FASTA path for r1_start")
p.add_argument("--r2_start", required=True, help="Output FASTA path for r2_start")
p.add_argument("--log", required=True, help="Log path (stdout/stderr appended)")
args = p.parse_args()

# Redirect stderr and stdout to Snakemake log
sys.stdout = open(args.log, "a")
sys.stderr = open(args.log, "a")
print("[INFO] Starting ex_generate_demux_adaptors.py")
print(f"[INFO]   lane={args.lane}")
print(f"[INFO]   r1_start_out={args.r1_start}")
print(f"[INFO]   r2_start_out={args.r2_start}")

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
out_r1 = Path(args.r1_start)
out_r2 = Path(args.r2_start)

if lane not in adapter_dict:
    available = ", ".join(sorted(adapter_dict.keys())[:10])
    suffix = " ..." if len(adapter_dict.keys()) > 10 else ""
    raise KeyError(f"Lane '{lane}' not found in adapter_dict. Available: {available}{suffix}")

sample_dict = adapter_dict[lane]
if not isinstance(sample_dict, dict) or not sample_dict:
    raise ValueError(f"Lane '{lane}' has no samples/controls in adapter_dict")

required_regions = ("r1_start", "r2_start")

# Validate required regions exist for at least the first sample (fail early with a helpful message)
first_sample_id = next(iter(sample_dict.keys()))
first_regions = sample_dict[first_sample_id].keys()
missing_first = [r for r in required_regions if r not in first_regions]
if missing_first:
    raise KeyError(
        f"Missing required region(s) {missing_first} for lane '{lane}' (sample '{first_sample_id}'). "
        f"Available regions: {', '.join(sorted(first_regions))}"
    )

# Ensure output directories exist
out_r1.parent.mkdir(parents=True, exist_ok=True)
out_r2.parent.mkdir(parents=True, exist_ok=True)

# -------------------------------------------------------------------------------------------
# Write FASTA(s)
# -------------------------------------------------------------------------------------------

records = 0
with open(out_r1, "w") as f_r1, open(out_r2, "w") as f_r2:
    for sample_id in sorted(sample_dict.keys()):
        region_dict = sample_dict[sample_id]

        for region in required_regions:
            if region not in region_dict:
                raise KeyError(f"Missing region '{region}' for lane '{lane}', sample '{sample_id}'")

        f_r1.write(f">{sample_id}\n{region_dict['r1_start']}\n")
        f_r2.write(f">{sample_id}\n{region_dict['r2_start']}\n")
        records += 1

if records == 0:
    raise ValueError(f"Wrote 0 records for lane '{lane}' (outputs: {out_r1}, {out_r2})")

print(f"[INFO] Wrote: {out_r1} ({records} records)")
print(f"[INFO] Wrote: {out_r2} ({records} records)")
print("[INFO] Finished ex_generate_demux_adaptors.py")