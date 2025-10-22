"""
--- ex_trimmed_read_length_metrics.py ---

Calculates the length of reads post trimming and outputs a distribution of read lengths.

This script is to be used exclusively with its parent rule ex_trimmed_read_length_metrics

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import sys
import subprocess
import numpy as np
import json

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


def safe_percentiles(lengths, percentiles):
    """Return percentile dict; if no lengths, return all zeros."""
    if len(lengths) == 0:
        return {f"{p}th": 0 for p in percentiles}
    return {f"{p}th": int(np.percentile(lengths, p)) for p in percentiles}


def main(snakemake):
    # Redirect stdout/stderr
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_trimmed_read_length_metrics.py")

    # Define inputs
    trimmed_r1 = snakemake.input.r1
    trimmed_r2 = snakemake.input.r2

    # Define sample name
    sample = snakemake.params.sample

    # Define output path
    output_json = snakemake.output.json

    # Collect lengths
    lengths_r1 = get_lengths_with_seqkit(trimmed_r1)
    lengths_r2 = get_lengths_with_seqkit(trimmed_r2)

    # Get totals
    total_reads = len(lengths_r1) + len(lengths_r2)
    zero_length_r1 = sum(1 for l in lengths_r1 if l == 0)
    zero_length_r2 = sum(1 for l in lengths_r2 if l == 0)
    zero_length_total = zero_length_r1 + zero_length_r2

    # Avoid division by zero
    percent_zero_length = (
        round(100 * zero_length_total / total_reads, 2) if total_reads > 0 else 0
    )

    # Percentiles
    percentiles = [0,0.25,0.5,0.75,1,5,10,20,30,40,50,90,100]
    pct_r1 = safe_percentiles(lengths_r1, percentiles)
    pct_r2 = safe_percentiles(lengths_r2, percentiles)

    # Output data to JSON
    output_data = {
        "description": "Read length percentiles after trimming",
        "sample": sample,
        "length_percentiles_r1": pct_r1,
        "length_percentiles_r2": pct_r2,
        "zero_length_reads_r1": zero_length_r1,
        "zero_length_reads_r2": zero_length_r2,
        "percent_zero_length": percent_zero_length,
    }

    with open(output_json, "w") as out:
        json.dump(output_data, out, indent=4)

    print("[INFO] Completed ex_trimmed_read_length_metrics.py")


if __name__ == "__main__":
    main(snakemake)

