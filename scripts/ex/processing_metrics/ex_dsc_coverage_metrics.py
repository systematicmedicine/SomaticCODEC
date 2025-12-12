#!/usr/bin/env python3
"""
--- ex_dsc_coverage_metrics.py ---

Calculates duplex sequencing coverage metrics

Authors: 
    - James Phie
    - Joshua Johnstone
    - Chat-GPT
"""
# Import libraries
import sys
import bisect
import json
import argparse
import pysam

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_dsc_coverage_metrics.py")

    # Load quality threshold
    BASE_QUALITY_THRESHOLD = int(args.base_quality_threshold)

    # Inputs from Snakemake
    bam_ex_dsc_path = args.bam_ex_dsc
    include_bed_path = args.include_bed
    ref_fai_path = args.ref_fai
    sample = args.sample

    # Output path
    json_out_path = args.json

    # Helper functions
    # Loads BED intervals to dict
    def load_bed_intervals(path):
        bed_dict = {}
        with open(path) as f:
            for line in f:
                # Skip empty lines
                if not line.strip():
                    continue
                # Extract chrom, start, end
                chrom, start, end = line.split()[:3]
                start, end = int(start), int(end)
                bed_dict.setdefault(chrom, []).append((start, end))
        # Sort by start pos
        for chrom in bed_dict:
            bed_dict[chrom].sort()
        return bed_dict

    # Checks if a position exists in BED intervals
    def in_intervals(chrom, pos, bed_dict):
        intervals = bed_dict.get(chrom, [])
        # Get last interval with start <= pos
        i = bisect.bisect_right(intervals, (pos, float('inf'))) - 1
        # Return TRUE if pos lies inside interval
        return i >= 0 and intervals[i][0] <= pos < intervals[i][1]

    # Get total genome positions from FAI
    ref_lengths = {}
    with open(ref_fai_path) as f:
        for line in f:
            chrom, length = line.split()[:2]
            ref_lengths[chrom] = int(length)
    total_genome_positions = sum(ref_lengths.values())

    # Load include BED intervals
    include_intervals = load_bed_intervals(include_bed_path)
    
    # Initialise counters
    ex_dsc_coverage_bases = 0
    ex_dsc_high_qual_bases = 0
    ex_dsc_high_qual_unmasked_bases = 0

    # Stream DSC BAM and check criteria for each position
    bam_ex_dsc = pysam.AlignmentFile(bam_ex_dsc_path, "rb")

    for position_pileup in bam_ex_dsc.pileup(stepper = "all", truncate = True):

        # Extract position and read pileup for this position
        chrom = position_pileup.reference_name
        pos = position_pileup.reference_pos
        depth = position_pileup.nsegments
        reads = position_pileup.pileups

        # Check each criterion for this position
        ex_dsc_coverage_check = False
        if depth > 0:
            ex_dsc_coverage_check = True

        ex_dsc_high_qual_check = False
        if ex_dsc_coverage_check:
            for read in reads:
                if not read.is_del and not read.is_refskip:
                    print(read.alignment.query_qualities[read.query_position])
                    if read.alignment.query_qualities[read.query_position] >= BASE_QUALITY_THRESHOLD:
                        ex_dsc_high_qual_check = True
                        break
        
        ex_dsc_high_qual_unmasked_check = False
        if ex_dsc_high_qual_check and in_intervals(chrom, pos, include_intervals):
            ex_dsc_high_qual_unmasked_check = True

        # Increment counters if criteria met
        if ex_dsc_coverage_check:
            ex_dsc_coverage_bases += 1

        if ex_dsc_high_qual_check:
            ex_dsc_high_qual_bases += 1

        if ex_dsc_high_qual_unmasked_check:
            ex_dsc_high_qual_unmasked_bases += 1

    bam_ex_dsc.close()

    # Calculate metrics
    ex_dsc_coverage = round((ex_dsc_coverage_bases / total_genome_positions) * 100, ndigits = 2)
    ex_dsc_high_qual = round((ex_dsc_high_qual_bases / total_genome_positions) * 100, ndigits = 2)
    ex_dsc_high_qual_unmasked = round((ex_dsc_high_qual_unmasked_bases / total_genome_positions) * 100, ndigits = 2)

    # Write output
    output_data = {
        "description": (
        "Duplex sequencing coverage metrics.",
        "Definitions:",
        "total_genome_positions: Number of positions in the reference genome.",
        "ex_dsc_coverage: Percentage of genome positions with DSC depth > 0.",
        "ex_dsc_high_qual: Percentage of genome positions that meet ex_dsc_coverage AND have base quality >= min_base_quality.",
        "ex_dsc_high_qual_unmasked: Percentage of genome positions that meet ex_dsc_high_qual AND are not masked.\nThese positions are eligible for variant calling."
        ),
        "sample": sample,
        "total_genome_positions": total_genome_positions,
        "ex_dsc_coverage": ex_dsc_coverage,
        "ex_dsc_high_qual": ex_dsc_high_qual,
        "ex_dsc_high_qual_unmasked": ex_dsc_high_qual_unmasked
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_dsc_coverage_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam_ex_dsc", required=True)
    parser.add_argument("--bai_ex_dsc", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--ref_fai", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--base_quality_threshold", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)