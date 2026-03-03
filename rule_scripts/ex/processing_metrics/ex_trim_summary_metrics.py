#!/usr/bin/env python3
"""
--- ex_trim_summary_metrics.py ---

Calculates the number of bases lost during ex_trim_fastq, the length percentiles for reads post trimming, percentage zero-length reads.

This script is to be used exclusively with its parent rule ex_trim_summary_metrics

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import sys
import subprocess
import numpy as np
import json
import argparse

# Helper functions
def count_bases(fastq_path: str, log_file):
        result = subprocess.run(
            ["seqkit", "stats", "-Ta", fastq_path],
            stdout=subprocess.PIPE,
            stderr=open(log_file, "a"),
            text=True,
            check=True
        )
        lines = [ln for ln in result.stdout.splitlines() if ln.strip()]
        header = lines[0].split("\t")
        row = lines[1].split("\t")
        idx_sum = header.index("sum_len")
        return int(row[idx_sum])

def get_lengths_with_seqkit(fastq):
    cmd = ["seqkit", "fx2tab", str(fastq)]
    lengths = []

    with subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True) as proc:
        for line in proc.stdout:
            line = line.rstrip("\n")
            if not line:
                continue
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            seq = parts[1]
            lengths.append(len(seq))
        proc.wait()

    return lengths

def get_percentiles(lengths, percentiles):
    """Return percentile dict; if no lengths, return all zeros."""
    if len(lengths) == 0:
        return {f"{p}th": 0 for p in percentiles}
    return {f"{p}th": int(np.percentile(lengths, p)) for p in percentiles}

def main(args):
    # Redirect stdout/stderr
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_trim_summary_metrics.py")

    # Define inputs
    demuxed_r1 = args.demuxed_r1
    demuxed_r2 = args.demuxed_r2
    trimmed_r1 = args.trimmed_r1
    trimmed_r2 = args.trimmed_r2

    # Define output path
    output_json = args.json

    # Calculate number and percentage of bases trimmed
    pre_total_bases = sum(count_bases(f, log_file = args.log) for f in [demuxed_r1, demuxed_r2])
    post_total_bases = sum(count_bases(f, log_file = args.log) for f in [trimmed_r1, trimmed_r2])
    trimmed_bases = pre_total_bases - post_total_bases
    trimmed_bases_pct = round(trimmed_bases / pre_total_bases * 100, 2) if pre_total_bases > 0 else 0.0

    # Collect read lengths post trimming
    lengths_r1 = get_lengths_with_seqkit(trimmed_r1)
    lengths_r2 = get_lengths_with_seqkit(trimmed_r2)

    # Define and caluclate read length percentiles
    percentiles = [0,0.25,0.5,0.75,1,5,10,20,30,40,50,90,100]
    read_length_percentiles_r1 = get_percentiles(lengths_r1, percentiles)
    read_length_percentiles_r2 = get_percentiles(lengths_r2, percentiles)

    # Calculate percent zero length reads
    total_reads = len(lengths_r1) + len(lengths_r2)
    zero_length_r1 = sum(1 for l in lengths_r1 if l == 0)
    zero_length_r2 = sum(1 for l in lengths_r2 if l == 0)
    zero_length_total = zero_length_r1 + zero_length_r2

    percent_zero_length = (
        round(100 * zero_length_total / total_reads, 2) if total_reads > 0 else 0
    )

    # Output data to JSON
    output_data = {
        "pre_trim_bases": {
            "description": "Number of bases in pre-trimming R1 and R2 FASTQs",
            "value": pre_total_bases
        },
        "post_trim_bases": {
            "description": "Number of bases in post-trimming R1 and R2 FASTQs",
            "value": post_total_bases
        },
        "trimmed_bases": {
            "description": "Number of bases lost during trimming (post_trim_bases - pre_trim_bases)",
            "value": trimmed_bases
        },
        "trimmed_bases_pct": {
            "description": "Percentage of total pre-trimming bases lost during trimming (trimmed_bases / pre_trim_bases * 100)",
            "value": trimmed_bases_pct
        },
        "read_length_percentiles_r1": {
            "description": "Read length percentiles after trimming for R1",
            "values": read_length_percentiles_r1
        },
        "read_length_percentiles_r2": {
            "description": "Read length percentiles after trimming for R2",
            "values": read_length_percentiles_r2
        },
        "zero_length_reads_r1": {
            "description": "Number of zero length reads after trimming for R1",
            "value": zero_length_r1
        },
        "zero_length_reads_r2": {
            "description": "Number of zero length reads after trimming for R2",
            "value": zero_length_r2
        },
        "zero_length_pct": {
            "description": "Percentage of total post-trimming reads that are zero-length",
            "value": percent_zero_length
        }
    }

    with open(output_json, "w") as out:
        json.dump(output_data, out, indent=4)

    print("[INFO] Completed ex_trim_summary_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--demuxed_r1", required=True)
    parser.add_argument("--demuxed_r2", required=True)
    parser.add_argument("--trimmed_r1", required=True)
    parser.add_argument("--trimmed_r2", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)

