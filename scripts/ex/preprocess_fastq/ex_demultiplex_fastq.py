#!/usr/bin/env python3
"""
--- ex_demultiplex_fastq.py ---

Demultiplex each lane specific FASTQ pair into sample and technical control FASTQ pairs

To be used exclusively with rule ex_demultiplex_fastq

Inputs:
  - Raw lane FASTQ files

Outputs:
  - FASTQ pairs for each sample and technical control
  - Metrics file

Authors:
    - Joshua Johnstone
"""

# Import libraries
import subprocess
from pathlib import Path
import argparse
import sys

parser = argparse.ArgumentParser(description="Demultiplex FASTQs")
parser.add_argument("--raw_r1", required=True, nargs="+")
parser.add_argument("--raw_r2", required=True, nargs="+")
parser.add_argument("--r1_start", required=True, nargs="+")
parser.add_argument("--r2_start", required=True, nargs="+")
parser.add_argument("--metrics", required=True, nargs="+")
parser.add_argument("--max_error_rate", required=True)
parser.add_argument("--min_adapter_overlap", required=True)
parser.add_argument("--lane_ids", required=True, nargs="+")
parser.add_argument("--suffix_r1", required=True)
parser.add_argument("--suffix_r2", required=True)
parser.add_argument("--out_dir", required=True)
parser.add_argument("--compression_level", required=True)
parser.add_argument("--threads", required=True)
parser.add_argument("--log", required=True)
args = parser.parse_args()

# Initiate logging
sys.stdout = open(args.log, "a")
sys.stderr = open(args.log, "a")
print("[INFO] Starting ex_demultiplex.py")

# Define inputs
raw_r1_files = {Path(file).parent.name: file for file in args.raw_r1}
raw_r2_files = {Path(file).parent.name: file for file in args.raw_r2}
r1_start_files = {Path(file).parent.name: file for file in args.r1_start}
r2_start_files = {Path(file).parent.name: file for file in args.r2_start}

# Define params
lane_ids = args.lane_ids
max_error_rate = float(args.max_error_rate)
min_adapter_overlap = int(args.min_adapter_overlap)
suffix_r1 = args.suffix_r1
suffix_r2 = args.suffix_r2
out_dir = args.out_dir
compression_level = int(args.compression_level)
threads = int(args.threads)

# Define outputs
metrics_files = {Path(file).parent.name: file for file in args.metrics}

# Loop over each lane
for lane in lane_ids:
    raw_r1 = raw_r1_files[lane]
    raw_r2 = raw_r2_files[lane]
    r1_fasta = r1_start_files[lane]
    r2_fasta = r2_start_files[lane]
    metrics_file = metrics_files[lane]

    cmd = [
        "cutadapt",
        "-j", str(threads),
        "--error-rate", str(max_error_rate),
        "--overlap", str(min_adapter_overlap),
        f"-g", f"^file:{r1_fasta}",
        f"-G", f"^file:{r2_fasta}",
        "--pair-adapters",
        "--report=full",
        "--action=none",
        "--discard-untrimmed",
        "-o", f"{out_dir}/{{name}}/{{name}}_{suffix_r1}",
        "-p", f"{out_dir}/{{name}}/{{name}}_{suffix_r2}",
        "--compression-level", str(compression_level),
        raw_r1,
        raw_r2
    ]

    with open(metrics_file, "w") as report_file, open(args.log, "a") as log_file:
        subprocess.run(cmd, stdout=report_file, stderr=log_file, text=True, check=True)

print("[INFO] Completed ex_demultiplex.py")
