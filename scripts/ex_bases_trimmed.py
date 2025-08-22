#!/usr/bin/env python3
"""
ex_bases_trimmed.py

Calculates the count and percentage of bases lost during ex_trim_fastq

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
# Import libraries
import json
import subprocess
from pathlib import Path
import sys

def main():
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_bases_trimmed.py")

    # Define JSON out path
    json_out_path = snakemake.output.json

    # Define sample name
    sample = snakemake.params.sample
    
    # Run command
    def run_cmd(cmd):
        res = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return res.stdout

    # Count total bases with seqkit stats
    def count_fastq_with_seqkit(fastq_path: Path) -> int:
        cmd = ["seqkit", "stats", "-Ta", str(fastq_path)]
        out = run_cmd(cmd)
        lines = [ln for ln in out.splitlines() if ln.strip()]
        header = lines[0].split("\t")
        row = lines[1].split("\t")
        idx_sum = header.index("sum_len")
        return int(row[idx_sum])

    # Use snakemake-provided inputs/outputs
    pre_files = [snakemake.input.pre_r1, snakemake.input.pre_r2]
    post_files = [snakemake.input.post_r1, snakemake.input.post_r2]

    pre_total = sum(count_fastq_with_seqkit(Path(f)) for f in pre_files)
    post_total = sum(count_fastq_with_seqkit(Path(f)) for f in post_files)

    trimmed_bases = pre_total - post_total
    percent_trimmed = round(trimmed_bases / pre_total * 100, 2) if pre_total > 0 else 0.0

    output_data = {
        "description": "Count and percentage of bases lost during ex_trim_fastq.",
        "sample": sample,
        "pre_trim_bases": pre_total,
        "post_trim_bases": post_total,
        "trimmed_bases": trimmed_bases,
        "percent_bases_trimmed": percent_trimmed,
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_bases_trimmed.py")

if __name__ == "__main__":
    main()