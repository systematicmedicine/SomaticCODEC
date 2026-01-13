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
import json
from helpers.fai_helpers import get_chrom_lengths
from helpers.bam_helpers import depth_array_BQ_bed

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
    ex_depth_high_qual_unmasked = depth_array_BQ_bed(ex_dsc_bam_path, chrom_lengths, EX_BQ_THRESHOLD, include_bed_path, THREADS)

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
