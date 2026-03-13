#!/usr/bin/env python3
"""
--- ex_snv_read_position_metrics.py ---

Determines the read position for each called SNV (as a percentile of read length), and writes a metrics file with percentiles for read position across all SNVs.

Authors:
  - Joshua Johnstone
  - Chat-GPT
"""

import pysam
import argparse
import sys
import numpy as np
import json
import matplotlib.pyplot as plt

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_snv_read_position_metrics.py")

    # Define input and output paths
    input_vcf_path = args.vcf
    input_bam_path = args.bam
    input_bai_path = args.bai # Implicit input for pysam .fetch
    output_json_path = args.json
    output_plot_path = args.plot

    # Define hardcoded params
    PERCENTILES = [0, 1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100]

    # Create VCF and BAM objects
    vcf = pysam.VariantFile(input_vcf_path)
    bam = pysam.AlignmentFile(input_bam_path, "rb")

    # Create list for read position percentiles (position of each SNV in each of the reads that cover it)
    read_position_fracs = []

    # Loop over SNV records
    for record in vcf:
        chrom = record.chrom
        snv_pos = record.pos - 1

        # Get reads that cover the SNV
        for read in bam.fetch(chrom, snv_pos, snv_pos+1):
            aligned_pairs = read.get_aligned_pairs(matches_only=True)
            for read_pos, ref_pos in aligned_pairs:
                if ref_pos == snv_pos:

                    # Assess only reads where SNV pos is alt
                    read_base = read.query_sequence[read_pos]
                    if read_base.upper() in record.alts:

                        # Append the read position as a fraction of read length
                        read_position_fracs.append((read_pos + 1) / read.query_length)
                        break

    # Calculate percentiles for read_position_fracs
    percentile_values = np.percentile(read_position_fracs, PERCENTILES)
    percentile_values_pct = percentile_values * 100
    percentile_dict = {f"{p}th": round(v, 2) for p, v in zip(PERCENTILES, percentile_values_pct)}

    # Write output to JSON
    output = {
    "read_position_percentiles": {
        "description": "Percentiles for average read position of each SNV (as a percentage of read length)",
        "values": percentile_dict}}
    
    with open(output_json_path, "w") as f:
        json.dump(output, f, indent=4)

    # Create and output histogram
    plt.figure()
    plt.hist(np.array(read_position_fracs) * 100, bins=50)
    plt.xlabel("Read position (% of read length)")
    plt.ylabel("Number of SNVs")
    plt.title("Distribution of SNV read positions")
    plt.tight_layout()
    plt.savefig(output_plot_path)
    plt.close()

    print(f"[INFO] Completed ex_snv_read_position_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--vcf", required=True)
    parser.add_argument("--bam", required=True)
    parser.add_argument("--bai", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--plot", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)