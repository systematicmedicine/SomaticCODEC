#!/usr/bin/env python3
"""
ex_bases_trimmed.py

Calculates the count and percentage of bases lost during ex_trim_fastq

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import subprocess
import sys
import argparse

def main(args):
    
    # Redirect stdout/stderr
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_bases_trimmed.py")

    # Inputs
    pre_files = [args.pre_r1, args.pre_r2]
    post_files = [args.post_r1, args.post_r2]
    json_out_path = args.json
    sample = args.sample

    def count_bases(fastq_path: str):
        result = subprocess.run(
            ["seqkit", "stats", "-Ta", fastq_path],
            stdout=subprocess.PIPE,
            stderr=open(args.log, "a"),
            text=True,
            check=True
        )
        lines = [ln for ln in result.stdout.splitlines() if ln.strip()]
        header = lines[0].split("\t")
        row = lines[1].split("\t")
        idx_sum = header.index("sum_len")
        return int(row[idx_sum])

    pre_total = sum(count_bases(f) for f in pre_files)
    post_total = sum(count_bases(f) for f in post_files)

    trimmed_bases = pre_total - post_total
    percent_trimmed = round(trimmed_bases / pre_total * 100, 2) if pre_total > 0 else 0.0

    output_data = {
        "description": "Count and percentage of bases lost during ex_trim_fastq.",
        "sample": sample,
        "pre_trim_bases": pre_total,
        "post_trim_bases": post_total,
        "trimmed_bases": trimmed_bases,
        "percent_bases_trimmed": percent_trimmed
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_bases_trimmed.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--pre_r1", required=True)
    parser.add_argument("--pre_r2", required=True)
    parser.add_argument("--post_r1", required=True)
    parser.add_argument("--post_r2", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)