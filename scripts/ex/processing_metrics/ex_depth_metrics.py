#!/usr/bin/env python3
"""
--- ex_depth_metrics.py ---

Generates depth metrics for the final EX DSC BAM

Authors:
    - Joshua Johnstone
    - Chat-GPT
"""

# Import libraries
import sys
import argparse
import numpy as np
import subprocess
import json

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_depth_metrics.py")

    # Define input paths  
    ex_dsc_bam_path = args.ex_dsc_bam
    include_bed_path = args.include_bed
    ref_fai_path = args.ref_fai

    # Define output paths
    json_out_path = args.output_json

    # Define params
    EX_BQ_THRESHOLD = int(args.ex_bq_threshold)
    THREADS = int(args.threads)

    # Helper functions
    # Returns a dict with [chrom][length] from FAI file
    def get_chrom_lengths(fai_path):
        chrom_lengths = {}
        with open(fai_path) as f:
            for line in f:
                chrom, length = line.strip().split("\t")[:2]
                chrom_lengths[chrom] = int(length)
        return chrom_lengths

    # Returns a dict with [chrom][start_index], and total genome length
    def get_chrom_offsets(chrom_lengths):
        offsets = {}
        genome_length = 0
        for chrom, length in chrom_lengths.items():
            offsets[chrom] = genome_length
            genome_length += length
        return offsets, genome_length
    
    # Creates an array for depth at each BAM position (at a given BQ threshold and within a given BED)
    def depth_array_BQ_BED(array_name, bam_path, chrom_lengths, BQ_threshold, BED_file, threads):

        print(f"[INFO] Started creating {array_name} array for {bam_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to 0 for all positions
        depth_array = np.zeros(genome_length, dtype=int)

        cmd = [
        "samtools", "depth",
        "--threads", str(threads),
        "-J",
        "-s",
        "--min-BQ", str(BQ_threshold), # Only bases with BQ >= threshold count towards depth
        "-b", str(BED_file), # Only bases within BED regions count towards depth
        bam_path
        ]

        with subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        ) as proc:

            for line in proc.stdout:
                chrom, pos_str, depth_str = line.split()
                pos = int(pos_str) - 1 # Convert position to 0-based
                depth = int(depth_str)
                genome_index = offsets[chrom] + pos

                # Add depth value to array
                depth_array[genome_index] = depth

        print(f"[INFO] Finished creating {array_name} array for {bam_path}")

        return depth_array
    
    # Calculates the percentage of a BED file covered at each depth threshold
    def pct_bed_coverage_at_depth_threshold(depth_array, bed_length, thresholds):

        # Calculate pct coverage
        pct_cov = {}

        for x in thresholds:
            pct_cov[f"{x}X"] = round(np.count_nonzero(depth_array >= x) / bed_length * 100, 2)

        return pct_cov
    
    # Calculates depth percentiles for array positions with depth > 0
    def depth_percentiles(depth_array, percentiles):

        depths = depth_array[depth_array >= 1]

        if len(depths) == 0:
            return {p: 0 for p in percentiles}

        # Compute requested percentiles
        percentile_values = np.percentile(depths, percentiles)
        percentile_dict = {f"{p}th": round(v, 2) for p, v in zip(percentiles, percentile_values)}

        return percentile_dict
    
    # Calculates the mean depth of array positions with depth > 0
    def mean_depth(depth_array):

        # Select depth values for positions in BED
        depths = depth_array[depth_array >= 1]
        
        # Calculate mean depth
        mean_depth = round(depths.mean(), 2) if len(depths) > 0 else 0

        return mean_depth
    
    # Gets the total length of regions in a BED file
    def bed_length(BED_file):
        length = 0
        with open(BED_file) as f:
            for line in f:
                chrom, start, end = line.strip().split()[:3]
                length += int(end) - int(start)
        return length

    # Get chromosome lengths from reference FAI
    chrom_lengths = get_chrom_lengths(ref_fai_path)

    # Create depth array
    ex_depth_high_qual_unmasked = depth_array_BQ_BED("ex_depth_high_qual_unmasked", ex_dsc_bam_path, chrom_lengths, EX_BQ_THRESHOLD, include_bed_path, THREADS)

    # Define depth thresholds
    depth_thresholds = [1, 2, 4, 6, 8, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 100]

    # Calculate percentage of include BED covered at each threshold
    include_bed_length = bed_length(include_bed_path)
    pct_depth_by_coverage = pct_bed_coverage_at_depth_threshold(ex_depth_high_qual_unmasked, include_bed_length, depth_thresholds)

    # Calculate depth percentiles for high_qual_unmasked positions
    percentiles = [0, 1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100]
    depth_percentiles_high_qual_unmasked = depth_percentiles(ex_depth_high_qual_unmasked, percentiles)

    # Write output to JSON
    output = {
    "definitions": {
        "ex_depth_high_qual_unmasked": "Positions with > 0 DSC depth AND base quality >= min_base_quality AND not masked"},
    "depth_percentiles": {
        "description": "Depth percentiles for ex_depth_high_qual_unmasked positions",
        "values": depth_percentiles_high_qual_unmasked},
    "pct_coverage": {
        "description": "Percentage of include BED covered by ex_depth_high_qual_unmasked positions at each depth threshold",
        "values": pct_depth_by_coverage}
    }

    with open(json_out_path, "w") as f:
        json.dump(output, f, indent=4)

    print("[INFO] Completed ex_depth_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--threads", required=True)
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--ex_bq_threshold", required=True)
    parser.add_argument("--output_json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
