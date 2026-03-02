#!/usr/bin/env python3
"""
--- ex_demultiplex_fastq.py ---

Demultiplex each lane specific FASTQ pair into sample FASTQ pairs

To be used exclusively with rule ex_demultiplex_fastq

Inputs:
  - Raw lane FASTQ files

Outputs:
  - FASTQ pairs for each sample
  - Metrics file

Authors:
    - Joshua Johnstone
"""

# Import libraries
import subprocess
from pathlib import Path
import argparse
import sys
import helpers.get_metadata as md

# Parse arguments
parser = argparse.ArgumentParser(description="Demultiplex FASTQs")
parser.add_argument("--raw_r1", required=True, nargs="+")
parser.add_argument("--raw_r2", required=True, nargs="+")
parser.add_argument("--r1_start", required=True, nargs="+")
parser.add_argument("--r2_start", required=True, nargs="+")
parser.add_argument("--demuxed_r1", required=True, nargs="+")
parser.add_argument("--demuxed_r2", required=True, nargs="+")
parser.add_argument("--metrics", required=True, nargs="+")
parser.add_argument("--max_error_rate", required=True)
parser.add_argument("--min_adapter_overlap", required=True)
parser.add_argument("--compression_level", required=True)
parser.add_argument("--ex_samples", required=True, nargs="+")
parser.add_argument("--threads", required=True)
parser.add_argument("--log", required=True)
args = parser.parse_args()

# Initiate logging
sys.stdout = open(args.log, "a")
sys.stderr = open(args.log, "a")
print("[INFO] Starting ex_demultiplex_fastq.py")

# Define inputs
raw_r1_files = {Path(file).parent.name: file for file in args.raw_r1}
raw_r2_files = {Path(file).parent.name: file for file in args.raw_r2}
r1_start_files = {Path(file).parent.name: file for file in args.r1_start}
r2_start_files = {Path(file).parent.name: file for file in args.r2_start}

# Define params
max_error_rate = float(args.max_error_rate)
min_adapter_overlap = int(args.min_adapter_overlap)
ex_samples = args.ex_samples
compression_level = int(args.compression_level)
threads = int(args.threads)

# Define outputs
demuxed_r1_files = {Path(file).parent.name: file for file in args.demuxed_r1}
demuxed_r2_files = {Path(file).parent.name: file for file in args.demuxed_r2}
metrics_files = {Path(file).parent.name: file for file in args.metrics}

# Create output file templates where {ex_sample} is replaced with {name} to enable cutadapt wildcarding
output_template_r1 = demuxed_r1_files[ex_samples[0]].replace(ex_samples[0], "{name}")
output_template_r2 = demuxed_r2_files[ex_samples[0]].replace(ex_samples[0], "{name}")

# Loop over each lane
for lane in raw_r1_files:
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
        "-o", str(output_template_r1),
        "-p", str(output_template_r2),
        "--compression-level", str(compression_level),
        raw_r1,
        raw_r2
    ]

    with open(metrics_file, "w") as report_file, open(args.log, "a") as log_file:
        subprocess.run(cmd, stdout=report_file, stderr=log_file, text=True, check=True)

print("[INFO] Completed ex_demultiplex_fastq.py")
