#!/usr/bin/env python3
"""
--- coverage_comparisons.py ---

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

def main(args):

    # Redirect stdout/stderr to Snakemake log
    # sys.stdout = open(args.log, "a")
    # sys.stderr = open(args.log, "a")
    print("[INFO] Starting coverage_comparisons.py")

    # Define input paths  
    difficult_regions_mask_path = args.difficult_regions_bed
    repeat_masker_mask_path = args.repeat_masker_bed
    gnomAD_mask_path = args.gnomAD_bed
    ms_bam_path = args.ms_bam
    include_bed_path = args.include_bed
    ex_dsc_bam_path = args.ex_dsc_bam
    ref_fai_path = args.ref_fai

    # Define output paths
    coverage_comparisons_path = args.comparisons_tsv

    # Define params
    MS_DEPTH_THRESHOLD = int(args.ms_depth_threshold)
    EX_DEPTH_THRESHOLD = int(args.ex_depth_threshold)
    MS_BQ_THRESHOLD = int(args.ms_bq_threshold)
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
    
    # Creates a boolean array for coverage at each position (at a given depth threshold)
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
    
    # Creates a boolean array for coverage at each position (at a given BQ threshold)
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

    # Create boolean arrays for BED files
    difficult_regions_coverage = coverage_array_bed(difficult_regions_mask_path, chrom_lengths)
    repeat_masker_coverage = coverage_array_bed(repeat_masker_mask_path, chrom_lengths)
    gnomAD_mask_coverage = coverage_array_bed(gnomAD_mask_path, chrom_lengths)
    include_bed_coverage = coverage_array_bed(include_bed_path, chrom_lengths)

    # Create boolean arrays for MS and EX coverage at given depth and BQ thresholds
    ms_coverage_depth = coverage_array_depth_threshold(ms_bam_path, chrom_lengths, MS_DEPTH_THRESHOLD, THREADS)
    ms_coverage_BQ = coverage_array_BQ_threshold(ms_bam_path, chrom_lengths, MS_BQ_THRESHOLD, THREADS)

    ex_coverage_depth = coverage_array_depth_threshold(ex_dsc_bam_path, chrom_lengths, EX_DEPTH_THRESHOLD, THREADS)
    ex_coverage_BQ = coverage_array_BQ_threshold(ex_dsc_bam_path, chrom_lengths, EX_BQ_THRESHOLD, THREADS)

    # Create dictionary for coverage metrics and arrays
    coverage_metrics_dict = {
        "difficult_regions": difficult_regions_coverage,
        "repeat_masker": repeat_masker_coverage,
        "gnomAD_mask": gnomAD_mask_coverage,
        "include_bed": include_bed_coverage,
        "ms_depth": ms_coverage_depth,
        "ms_BQ": ms_coverage_BQ,
        "ex_depth": ex_coverage_depth,
        "ex_BQ": ex_coverage_BQ
    }

    # Create coverage matrix
    coverage_metric_names = list(coverage_metrics_dict.keys())
    number_of_metrics = len(coverage_metric_names)
    coverage_matrix = np.zeros((number_of_metrics, number_of_metrics), dtype=float)

    for row_index, metric_a in enumerate(coverage_metric_names):
        for col_index, metric_b in enumerate(coverage_metric_names):
            overlap = coverage_metrics_dict[metric_a] & coverage_metrics_dict[metric_b]
            coverage_matrix[row_index, col_index] = 100 * np.sum(overlap) / genome_length

    # Write to TSV
    with open(coverage_comparisons_path, "w") as out:
        out.write("metric_a\tmetric_b\tpct_genome\n")
        for metric_a_index, metric_a in enumerate(coverage_metric_names):
            for metric_b_index, metric_b in enumerate(coverage_metric_names):
                # Skip duplicate comparisons
                if metric_b_index < metric_a_index:
                    continue  
                overlap = coverage_metrics_dict[metric_a] & coverage_metrics_dict[metric_b]
                pct = 100.0 * np.sum(overlap) / genome_length
                out.write(f"{metric_a}\t{metric_b}\t{pct:.2f}\n")

    print("[INFO] Completed coverage_comparisons.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--threads", required=True)
    parser.add_argument("--difficult_regions_bed", required=True)
    parser.add_argument("--repeat_masker_bed", required=True)
    parser.add_argument("--gnomAD_bed", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--ms_bam", required=True)
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--ms_depth_threshold", required=True)
    parser.add_argument("--ex_depth_threshold", required=True)
    parser.add_argument("--ms_bq_threshold", required=True)
    parser.add_argument("--ex_bq_threshold", required=True)
    parser.add_argument("--comparisons_tsv", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)