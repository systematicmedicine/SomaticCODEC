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
import csv

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
    output_csv_path = args.csv

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
        for read in bam.fetch(chrom, pos-1, pos):
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

                    # Skip reads where SNV would be outside effective region
                    if read_pos not in effective_length_index:
                        continue

                    # Check each ALT separately
                    for alt in alts:
                        if read_seq[read_pos] == alt.upper():
                            read_pos_frac = (effective_length_index[read_pos] + 1) / effective_length
                            read_position_fracs.append(read_pos_frac)
                            # Record row for CSV
                            csv_rows.append({
                                "chrom": chrom,
                                "pos": pos,
                                "ref": ref,
                                "alt": alt,
                                "read_pos_pct": round(read_pos_frac * 100, 2)
                            })
                            break  # Stop after first ALT match for read

    # Create and output histogram
    plt.figure()
    plt.hist(np.array(read_position_fracs) * 100, bins=50)
    plt.xlabel("Read position (% of read length)")
    plt.ylabel("Number of SNVs")
    plt.title("Distribution of SNV read positions")
    plt.tight_layout()
    plt.savefig(output_plot_path)
    plt.close()

    # CSV output
    with open(output_csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["chrom","pos","ref","alt","read_pos_pct"])
        writer.writeheader()
        writer.writerows(csv_rows)

    print(f"[INFO] Completed ex_snv_read_position_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--vcf", required=True)
    parser.add_argument("--bam", required=True)
    parser.add_argument("--bai", required=True)
    parser.add_argument("--csv", required=True)
    parser.add_argument("--plot", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)