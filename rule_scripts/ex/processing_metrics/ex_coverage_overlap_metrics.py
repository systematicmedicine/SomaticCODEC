#!/usr/bin/env python3
"""
--- ex_coverage_overlap_metrics.py ---

Compares overlap between various coverage metrics

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
from pathlib import Path
from helpers.fai_helpers import get_chrom_lengths, get_chrom_offsets

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_coverage_overlap_metrics.py")

    # Define input paths  
    precomputed_mask_paths = args.precomputed_masks
    ms_bam_path = args.ms_bam
    lowdepth_bed_path = args.lowdepth_bed
    germ_risk_bed_path = args.germ_risk_bed
    combined_bed_path = args.combined_bed
    include_bed_path = args.include_bed
    ex_dsc_bam_path = args.ex_dsc_bam
    ref_fai_path = args.ref_fai

    # Define output paths
    output_json_path = args.output_json

    # Define params
    MS_DEPTH_THRESHOLD = int(args.ms_depth_threshold)
    EX_DEPTH_THRESHOLD = int(args.ex_depth_threshold)
    MS_BQ_THRESHOLD = int(args.ms_bq_threshold)
    EX_BQ_THRESHOLD = int(args.ex_bq_threshold)
    THREADS = int(args.threads)

    # Helper functions    
    # Creates a boolean array for BED file coverage
    def coverage_array_bed(bed_path, chrom_lengths):

        print(f"[INFO] Started creating coverage array for {bed_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array = np.zeros(genome_length, dtype=bool)

        # Mark BED-covered positions as True
        with open(bed_path) as bed:
            for line in bed:
                if line.startswith("#") or not line.strip():
                    continue

                chrom, start, end = line.rstrip().split()[:3]
                start = int(start)
                end = int(end)

                genome_start = offsets[chrom] + start
                genome_end = offsets[chrom] + end

                coverage_array[genome_start:genome_end] = True

        print(f"[INFO] Finished creating coverage array for {bed_path}")

        return coverage_array
    
    # Creates a boolean array for coverage at each BAM position (at a given depth threshold)
    def coverage_array_depth_threshold(bam_path, chrom_lengths, depth_threshold, threads):

        print(f"[INFO] Started creating depth coverage array for {bam_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array_depth = np.zeros(genome_length, dtype=bool)

        cmd = [
        "samtools", "depth",
        "--threads", str(threads),
        "-J",
        "-s",
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

                # If depth >= threshold, set coverage to True
                if depth >= depth_threshold:
                    coverage_array_depth[genome_index] = True

        print(f"[INFO] Finished creating depth coverage array for {bam_path}")

        return coverage_array_depth
    
    # Creates a boolean array for coverage at each BAM position (at a given BQ threshold)
    def coverage_array_BQ_threshold(bam_path, chrom_lengths, BQ_threshold, threads):

        print(f"[INFO] Started creating BQ coverage array for {bam_path}")
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array_BQ = np.zeros(genome_length, dtype=bool)

        cmd = [
        "samtools", "depth",
        "--threads", str(threads),
        "-J",
        "-s",
        "--min-BQ", str(BQ_threshold), # Only bases with BQ >= threshold count towards depth
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

                # If any depth with BQ >= threshold, set coverage to True
                if depth > 0:
                    coverage_array_BQ[genome_index] = True

        print(f"[INFO] Finished creating BQ coverage array for {bam_path}")

        return coverage_array_BQ

    # Get chromosome lengths from reference FAI
    chrom_lengths = get_chrom_lengths(ref_fai_path)

    # Get genome length
    _, genome_length = get_chrom_offsets(chrom_lengths)

    # Create boolean array for reference genome
    ref_genome_coverage = np.ones(genome_length, dtype=bool)

    # Create boolean arrays for BED files
    # Map mask names to BED files
    bed_files = {}
    bed_coverage_arrays = {}

    # Name precomputed masks by file basename (without extension)
    for bed_file in precomputed_mask_paths:
        name = Path(bed_file).stem
        bed_files[name] = bed_file

    # Add other masks
    bed_files.update({
        "lowdepth": lowdepth_bed_path,
        "ms_germ_risk": germ_risk_bed_path,
        "combined_mask": combined_bed_path,
        "include_bed": include_bed_path
    })

    for mask_name, bed_path in bed_files.items():
        bed_coverage_arrays[mask_name] = coverage_array_bed(bed_path, chrom_lengths)

    # Create boolean arrays for MS and EX coverage at given depth and BQ thresholds
    ms_coverage_depth = coverage_array_depth_threshold(ms_bam_path, chrom_lengths, MS_DEPTH_THRESHOLD, THREADS)
    ms_coverage_BQ = coverage_array_BQ_threshold(ms_bam_path, chrom_lengths, MS_BQ_THRESHOLD, THREADS)

    ex_coverage_depth = coverage_array_depth_threshold(ex_dsc_bam_path, chrom_lengths, EX_DEPTH_THRESHOLD, THREADS)
    ex_coverage_BQ = coverage_array_BQ_threshold(ex_dsc_bam_path, chrom_lengths, EX_BQ_THRESHOLD, THREADS)

    # Create dictionary for coverage metrics and arrays
    coverage_metrics_dict = {}

    for mask_name, coverage_array in bed_coverage_arrays.items():
        coverage_metrics_dict[mask_name] = coverage_array

    coverage_metrics_dict.update({
        "ref_genome": ref_genome_coverage,
        "ms_depth": ms_coverage_depth,
        "ms_BQ": ms_coverage_BQ,
        "ex_depth": ex_coverage_depth,
        "ex_BQ": ex_coverage_BQ
    })

    # Compute overlaps and write to JSON
    overlap_results = {}

    coverage_metric_names = list(coverage_metrics_dict.keys())

    for metric_a_index, metric_a in enumerate(coverage_metric_names):
        for metric_b_index, metric_b in enumerate(coverage_metric_names):

            if metric_b_index < metric_a_index:
                continue # Skip duplicate comparisons

            union = coverage_metrics_dict[metric_a] | coverage_metrics_dict[metric_b]
            overlap = coverage_metrics_dict[metric_a] & coverage_metrics_dict[metric_b]

            overlap_bases = int(np.sum(overlap))
            union_bases = int(np.sum(union))
            pct = 100 * overlap_bases / union_bases if union_bases > 0 else 0

            key = f"{metric_a}_vs_{metric_b}"

            overlap_results[key] = {
                "union_bases": union_bases,
                "overlap_bases": overlap_bases,
                "pct_overlap": round(pct, 2)
            }

    with open(output_json_path, "w") as out:
        json.dump(overlap_results, out, indent=2)

    print("[INFO] Completed ex_coverage_overlap_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--threads", required=True)
    parser.add_argument("--precomputed_masks", required=True, nargs = "+")
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--ms_bam", required=True)
    parser.add_argument("--lowdepth_bed", required=True)
    parser.add_argument("--germ_risk_bed", required=True)
    parser.add_argument("--combined_bed", required=True)
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--ms_depth_threshold", required=True)
    parser.add_argument("--ex_depth_threshold", required=True)
    parser.add_argument("--ms_bq_threshold", required=True)
    parser.add_argument("--ex_bq_threshold", required=True)
    parser.add_argument("--output_json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)