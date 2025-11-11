#!/usr/bin/env python3
"""
--- ex_dsc_remap_metrics.py ---

Extract basic realignment metrics from the double stranded consensus bam.

1. Percentage of total reads which successfully aligned to the reference genome
2. Percentage of total reads with a mapQ score of at least 60. 

Authors: 
    - James Phie
    - Joshua Johnstone
"""
# Import libraries
import subprocess
import sys
import json
import argparse

def main(args):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_dsc_remap_metrics.py")

    # Inputs from Snakemake
    dsc_bam = args.bam
    min_mapq = args.min_mapq
    sample = args.sample

    # Output path
    json_out_path = args.metrics

    def count_reads(cmd):
        """Run a samtools view command and return the count as int"""
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            sys.stderr.write(f"Command failed: {cmd}\n{result.stderr}")
            sys.exit(1)
        return int(result.stdout.strip())

    # Count total reads
    total_reads = count_reads(f"samtools view -c {dsc_bam}")

    # Count mapped reads (excluding unmapped)
    mapped_reads = count_reads(f"samtools view -F 0x4 -c {dsc_bam}")

    # Count mapped reads with MAPQ ≥ min MAPQ threshold
    over_min_MAPQ_reads = count_reads(f"samtools view -F 0x4 -q {min_mapq} -c {dsc_bam}")

    # Compute metrics
    aligned_pct = round(100 * mapped_reads / total_reads if total_reads else 0, 1)
    over_min_MAPQ_pct = round(100 * over_min_MAPQ_reads / mapped_reads if mapped_reads else 0, 1)
    reads_lost_to_MAPQ = round(100 - over_min_MAPQ_pct, 1)

    # Write output
    output_data = {
        "description": (
        "Basic realignment metrics from the double stranded consensus bam."
        ),
        "sample": sample,
        "total_reads": total_reads,
        "mapped_reads": mapped_reads,
        "percentage_mapped": aligned_pct,
        "reads_with_MAPQ_over_MAPQ_threshold": over_min_MAPQ_reads,
        "percentage_mapped_and_over_MAPQ_threshold": over_min_MAPQ_pct,
        "reads_lost_to_MAPQ_filter": reads_lost_to_MAPQ
    }

    # Write to JSON
    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_dsc_remap_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam", required=True)
    parser.add_argument("--metrics", required=True)
    parser.add_argument("--min_mapq", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)