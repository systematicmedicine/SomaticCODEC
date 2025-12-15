#!/usr/bin/env python3
"""
--- ex_ms_overlap_metrics.py ---

Calculates metrics for the overlap between EX and MS coverage

Authors:
    - Joshua Johnstone
    - Chat-GPT
"""

# Import libraries
import sys
import argparse
import pysam
import numpy as np
import json

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_ms_overlap_metrics.py")

    # Define input paths
    ex_dsc_bam_path = args.ex_dsc_bam
    ms_bam_path = args.ms_bam
    ref_fai_path = args.ref_fai

    # Define output paths
    json_out_path = args.json

    # Define params
    EX_DEPTH_THRESHOLD = 1
    MS_DEPTH_THRESHOLD = args.ms_depth_threshold

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
    
    # Creates a boolean array for coverage at each position (at a given depth threshold)
    def create_coverage_array(bam_path, chrom_lengths, depth_threshold):
        
        # Get chromosome offsets to caclulate array indices
        offsets, genome_length = get_chrom_offsets(chrom_lengths)

        # Set coverage to False for all positions
        coverage_array = np.zeros(genome_length, dtype=bool)

        bam = pysam.AlignmentFile(bam_path, "rb")
        for pileup in bam.pileup(stepper="all", truncate=True):
            chrom = pileup.reference_name
            pos = pileup.reference_pos
            depth = pileup.nsegments

            # If depth >= threshold, set coverage to True
            if depth >= depth_threshold:
                genome_index = offsets[chrom] + pos
                coverage_array[genome_index] = True

        return coverage_array

    # Get chromosome lengths from reference FAI
    chrom_lengths = get_chrom_lengths(ref_fai_path)

    # Create boolean array for EX DSC coverage (>0x depth)
    ex_coverage = create_coverage_array(ex_dsc_bam_path, chrom_lengths, EX_DEPTH_THRESHOLD)

    # Create boolean array for MS coverage (> half MS depth threshold)
    ms_coverage = create_coverage_array(ms_bam_path, chrom_lengths, MS_DEPTH_THRESHOLD)

    # Compare EX and MS coverage
    ex_or_ms_bases = int(np.sum(ex_coverage | ms_coverage))
    ex_and_ms_bases = int(np.sum(ex_coverage & ms_coverage))
    ex_only_bases = int(np.sum(ex_coverage & (~ms_coverage)))
    ms_only_bases = int(np.sum((~ex_coverage) & ms_coverage))
    
    # Compute metrics
    ex_and_ms_pct = round((ex_and_ms_bases / ex_or_ms_bases) * 100, ndigits = 2)
    ex_only_pct = round((ex_only_bases / ex_or_ms_bases) * 100, ndigits = 2)
    ms_only_pct = round((ms_only_bases / ex_or_ms_bases) * 100, ndigits = 2)

    # Write output
    output_data = {
        "ex_or_ms_bases": {
            "description": "Number of bases with EX depth >= 1 or MS coverage >= MS depth threshold",
            "value": ex_or_ms_bases
            },
        "ex_and_ms_pct": {
            "description": "Percentage of ex_or_ms_bases with EX depth >= 1 and MS coverage >= MS depth threshold",
            "value": ex_and_ms_pct
            },
        "ex_only_pct": {
            "description": "Percentage of ex_or_ms_bases with EX depth >= 1 but MS coverage < MS depth threshold",
            "value": ex_only_pct
            },
        "ms_only_pct": {
            "description": "Percentage of ex_or_ms_bases with MS coverage >= MS depth threshold but no EX depth",
            "value": ms_only_pct
            }        
        }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_ms_overlap_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ex_dsc_bam", required=True)
    parser.add_argument("--ms_bam", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--ms_depth_threshold", required=True)
    args = parser.parse_args()
    main(args=args)
