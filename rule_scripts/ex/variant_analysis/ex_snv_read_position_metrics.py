#!/usr/bin/env python3
"""
--- ex_snv_read_position_metrics.py ---

Calculates the read position for each called SNV (as a percentage of read length) and creates a plot.

Authors:
  - Joshua Johnstone
  - Chat-GPT
"""

import pysam
import argparse
import sys
import numpy as np
import matplotlib.pyplot as plt
import json

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_snv_read_position_metrics.py")

    # Define input and output paths
    input_vcf_path = args.vcf
    input_bam_path = args.bam
    input_bai_path = args.bai # Implicit input for pysam .fetch
    output_plot_path = args.plot
    output_json_path = args.json

    # Create VCF and BAM objects
    vcf = pysam.VariantFile(input_vcf_path)
    bam = pysam.AlignmentFile(input_bam_path, "rb")

    # Create list for read position percentiles (position of each SNV in each of the reads that cover it)
    read_position_fracs = []
    csv_rows = []

    # Loop over SNV records
    for record in vcf:
        chrom = record.chrom
        pos = record.pos
        ref = record.ref
        alts = record.alts

        # Loop over reads that cover SNV position
        for read in bam.fetch(chrom, pos - 1, pos):
            aligned_pairs = read.get_aligned_pairs(matches_only=True)
            read_seq = read.query_sequence.upper()
            aq = read.get_tag("aq")
            bq = read.get_tag("bq")

            # Count effective read length (length minus softclipped and SS overhang bases)
            effective_length_positions = [
                read_pos for read_pos, ref_pos in aligned_pairs # Aligned pairs excludes softclipped bases
                if aq[read_pos] != "!" and bq[read_pos] != "!" # SS overhang bases have quality of 0 (!)
            ]
            effective_length = len(effective_length_positions)
            effective_length_index = {pos: i for i, pos in enumerate(effective_length_positions)}

            # Find position covering SNV
            for read_pos, ref_pos in aligned_pairs:
                if ref_pos == pos - 1:

                    # Skip reads where SNV would be outside effective length region
                    if read_pos not in effective_length_index:
                        continue

                    # Check each ALT separately
                    for alt in alts:
                        if read_seq[read_pos] == alt.upper():
                            read_pos_frac = (effective_length_index[read_pos] + 1) / effective_length
                            read_position_fracs.append(read_pos_frac)
                            break  # Stop after first ALT match for read

    # Calculate cumulative distribution functions (empirical and uniform)
    snv_read_pos_pct = np.sort(np.array(read_position_fracs) * 100)
    num_snvs = len(snv_read_pos_pct)

    empirical_cdf = np.arange(1, num_snvs + 1) / num_snvs
    uniform_cdf = snv_read_pos_pct / 100

    # Calculate mean and max absolute deviation in area between empirical CDF and uniform CDF
    mean_area_diff = np.sum(np.abs(empirical_cdf - uniform_cdf)) / num_snvs
    max_area_diff = np.max(np.abs(empirical_cdf - uniform_cdf))

    # Create CDF plot
    plt.figure(figsize=(6, 4))
    plt.plot([0, 100], [0, 1], color = 'red', linestyle = '--', label = "Uniform CDF")
    plt.step(snv_read_pos_pct, empirical_cdf, where = 'post', label = "Empirical CDF")
    plt.xlabel("Read position (% of read length)")
    plt.ylabel("Cumulative fraction of SNVs")
    plt.title("Cumulative distribution function of SNV read positions")
    plt.legend()
    plt.tight_layout()
    plt.savefig(output_plot_path)
    plt.close()

    # Write JSON
    json_data = {
        "cdf_mean_difference": {
            "description": "Mean absolute difference between empirical and uniform cumulative distribution functions for SNV read positions",
            "value": round(mean_area_diff, 3)
        },
        "cdf_max_difference": {
            "description": "Maximum absolute difference between empirical and uniform cumulative distribution functions for SNV read positions",
            "value": round(max_area_diff, 3)
        }
    }

    with open(output_json_path, "w") as f:
        json.dump(json_data, f, indent=2)

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