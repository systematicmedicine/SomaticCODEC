#!/usr/bin/env python3
"""
--- ex_dsc_coverage_metrics.py ---

Calculate duplex sequencing coverage metrics:

1. Mean analyzable duplex depth across variant calling regions (selected per sample with include_bed)
2. Percent of variant calling positions with >0x coverage (selected per sample with include_bed)
3. Percent of whole genome positions with >0x coverage

Only bases with high base quality scores (>= QUALITY_THRESHOLD, typically >=Q70) are considered for depth and coverage calculations (e.g. duplex bases made from 2 Q35 bases).

Inputs:
- Filtered DSC BAM file
- Include BED file which excludes difficult to call regions (GIAB difficult regions), low depth germline regions, and germline mutations
- MS low depth bed
- Reference FAI file

Authors: 
    - James Phie
    - Joshua Johnstone
    - Chat-GPT
"""
# Import libraries
import sys
import subprocess
import bisect
import json
import argparse

def main(args):

    # Redirect stdout/stderr to Snakemake log
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_dsc_coverage_metrics.py")

    # Load quality threshold
    QUALITY_THRESHOLD = args.quality_threshold

    # Inputs from Snakemake
    bam_ex_dsc = args.bam_ex_dsc
    ms_depth = args.ms_depth
    include_bed = args.include_bed
    ref_fai = args.fai
    sample = args.sample
    ms_depth_threshold = int(args.ms_depth_threshold)

    # Output path
    json_out_path = args.metrics

    # Load include BED intervals
    def load_bed(path):
        bed = {}
        with open(path) as f:
            for line in f:
                if not line.strip():
                    continue
                chrom, start, end = line.split()[:3]
                start, end = int(start), int(end)
                bed.setdefault(chrom, []).append((start, end))
        for chrom in bed:
            bed[chrom].sort()
        return bed

    include_intervals = load_bed(include_bed)

    # Get genome length from FAI
    ref_lengths = {}
    with open(ref_fai) as f:
        for line in f:
            chrom, length = line.split()[:2]
            ref_lengths[chrom] = int(length)

    total_genome_positions = sum(ref_lengths.values())

    # Checks if a position exists in BED intervals
    def in_intervals(chrom, pos, bed_dict):
        intervals = bed_dict.get(chrom, [])
        i = bisect.bisect_right(intervals, (pos, float('inf'))) - 1
        return i >= 0 and intervals[i][0] <= pos < intervals[i][1]

    # Precompute BED total positions
    include_bed_total_positions = sum(end - start for intervals in include_intervals.values() for start, end in intervals)

    # Get MS depth > half depth threshold positions
    ms_half_depth_threshold = ms_depth_threshold / 2
    ms_depth_half_positions = {}
    total_ms_half_depth_bases = 0

    with open(ms_depth, "r") as f:
        for line in f:
            chrom, pos_str, depth_str = line.split()
            pos = int(pos_str) - 1
            depth = int(depth_str)
            if depth > ms_half_depth_threshold:
                ms_depth_half_positions.setdefault(chrom, set()).add(pos)
                total_ms_half_depth_bases += 1

    # Get duplex depth >0 positions and compare overlap with MS
    total_include_bed_depth = 0
    total_ex_duplex_depth_bases = 0
    total_include_bed_covered_positions = 0
    total_ex_and_ms_bases = 0
    ex_and_ms_depth_positions = set()
    total_ex_not_ms_bases = 0

    with open(args.log, "a") as log_file:
        proc_ex = subprocess.Popen(
        ["samtools", "depth", "-q", str(QUALITY_THRESHOLD), "-a", bam_ex_dsc],
        stdout=subprocess.PIPE,
        stderr=log_file,
        text=True
    )

    for line in proc_ex.stdout:
        chrom, pos_str, depth_str = line.split()
        pos = int(pos_str) - 1
        depth = int(depth_str)

        in_bed = in_intervals(chrom, pos, include_intervals)
        in_ms = pos in ms_depth_half_positions.get(chrom, set())

        if depth > 0:
            total_ex_duplex_depth_bases += 1
            if in_ms:
                total_ex_and_ms_bases += 1
                ex_and_ms_depth_positions.add((chrom, pos))
            else:
                total_ex_not_ms_bases += 1

        if in_bed:
            total_include_bed_depth += depth
            if depth > 0:
                total_include_bed_covered_positions += 1

    proc_ex.stdout.close()
    proc_ex.wait()

    total_ms_not_ex_bases = 0
    for chrom, positions in ms_depth_half_positions.items():
        for pos in positions:
            if (chrom, pos) not in ex_and_ms_depth_positions:
                total_ms_not_ex_bases += 1

    # Calculate metrics
    total_ex_or_ms_bases = (total_ex_duplex_depth_bases + total_ms_half_depth_bases - total_ex_and_ms_bases)

    ex_duplex_coverage = round((total_ex_duplex_depth_bases / total_genome_positions * 100) if total_genome_positions else 0, 2)
    ms_half_depth_coverage = round((total_ms_half_depth_bases / total_genome_positions * 100) if total_genome_positions else 0, 2)
    coverage_ex_or_ms = round((total_ex_or_ms_bases / total_genome_positions * 100) if total_genome_positions else 0, 2)
    coverage_ex_not_ms = round((total_ex_not_ms_bases / total_ex_duplex_depth_bases * 100) if total_ex_duplex_depth_bases else 0, 2)
    coverage_ms_not_ex = round((total_ms_not_ex_bases / total_ms_half_depth_bases * 100) if total_ms_half_depth_bases else 0, 2)
    coverage_overlap_ex_ms = round((total_ex_and_ms_bases / total_ex_or_ms_bases * 100) if total_ex_or_ms_bases else 0, 2)
    ex_dsc_coverage_wholegenome = round((total_include_bed_covered_positions / total_genome_positions * 100) if total_genome_positions else 0, 2)
    include_bed_coverage = round((include_bed_total_positions / total_genome_positions * 100) if total_genome_positions else 0, 2)
    ex_dsc_coverage_bedregions = round((total_include_bed_covered_positions / include_bed_total_positions * 100) if include_bed_total_positions else 0, 2)
    ex_mean_analyzable_duplex_depth = round((total_include_bed_depth / include_bed_total_positions) if include_bed_total_positions else 0, 2)

    # Write output
    output_data = {
        "sample": sample,
        "total_genome_positions": {
            "value": total_genome_positions,
            "description": "Number of positions in the reference genome"
        },
        "ex_duplex_coverage": {
            "value": ex_duplex_coverage,
            "description": "Percentage of genome positions with duplex depth > 0"
        },
        "ms_half_depth_coverage": {
            "value": ms_half_depth_coverage,
            "description": "Percentage of genome positions with MS depth > half MS depth threshold"
        },
        "coverage_ex_or_ms": {
            "value": coverage_ex_or_ms,
            "description": "Percentage of genome positions with EX duplex depth > 0 OR MS depth > half MS depth threshold"
        },
        "coverage_ex_not_ms": {
            "value": coverage_ex_not_ms,
            "description": "Percentage of positions with EX duplex depth > 0 that do not have MS depth > half MS depth threshold"
        },
        "coverage_ms_not_ex": {
            "value": coverage_ms_not_ex,
            "description": "Percentage of positions with MS depth > half MS depth threshold that do not have EX duplex depth > 0"
        },
        "coverage_overlap_ex_ms": {
            "value": coverage_overlap_ex_ms,
            "description": "Percentage of sequenced positions with 1. MS depth > half MS depth threshold AND 2. EX duplex depth > 0"
        },
        "ex_dsc_coverage_wholegenome": {
            "value": ex_dsc_coverage_wholegenome,
            "description": "Percentage of genome positions eligible for variant calling (duplex depth > 0 & unmasked)"
        },
        "include_bed_total_positions": {
            "value": include_bed_total_positions,
            "description": "Number of positions in the include BED file"
        },
        "include_bed_coverage": {
            "value": include_bed_coverage,
            "description": "Percentage of genome positions in the include BED file"
        },
        "ex_dsc_coverage_bedregions": {
            "value": ex_dsc_coverage_bedregions,
            "description": "Percentage of include BED positions with EX duplex depth > 0"
        },
        "ex_mean_analyzable_duplex_depth": {
            "value": ex_mean_analyzable_duplex_depth,
            "description": "Mean duplex depth of positions eligible for variant calling (duplex depth > 0 & unmasked)"
        }                 
    }

    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_dsc_coverage_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam_ex_dsc", required=True)
    parser.add_argument("--bai_ex_dsc", required=True)
    parser.add_argument("--ms_depth", required=True)
    parser.add_argument("--fai", required=True)
    parser.add_argument("--metrics", required=True)
    parser.add_argument("--quality_threshold", required=True)
    parser.add_argument("--include_bed", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--ms_depth_threshold", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)