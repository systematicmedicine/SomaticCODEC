#!/usr/bin/env python3
"""
--- ex_call_dsc_metrics.py ---

Generates a summary file with the percentage of reads lost during ex_call_dsc

To be used with rule ex_call_dsc_metrics

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import json
import sys
import argparse

def main(args):
    # Redirect stdout and stderr to log file
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_call_dsc_metrics.py")

    # Load Snakemake inputs
    pre_call_bam_path = args.pre_call_bam
    post_call_bam_path = args.post_call_bam
    json_out_path = args.call_dsc_metrics
    sample = args.sample

    # Count primary aligned reads in a BAM
    def count_reads(bam_path):
        with open(args.log, "a") as log_file:
            result = subprocess.run(
                ["samtools", "view", "-c", "-F", "0x900", bam_path],
                stdout=subprocess.PIPE,
                stderr=log_file,
                text=True,
                check=True
            )
        return int(result.stdout.strip())

    # Calculate reads pre and post calling dsc
    pre_reads = count_reads(pre_call_bam_path)
    post_reads = count_reads(post_call_bam_path)
    reads_lost = round(100 * (pre_reads - post_reads) / pre_reads, 1)

    # Write data to JSON
    output_data = {
        "description": "Percentage of reads lost during ex_call_dsc.",
        "sample": sample,
        "reads_lost": reads_lost
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_call_dsc_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--pre_call_bam", required=True)
    parser.add_argument("--post_call_bam", required=True)
    parser.add_argument("--call_dsc_metrics", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
