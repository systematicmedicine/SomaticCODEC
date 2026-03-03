#!/usr/bin/env python3
"""
--- multimapping_read_metrics.py ---

Generates a summary file with the percentage of reads that mapped to multiple positions

To be used with any rule that generates multimapping metrics for a BAM file

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import pysam
import argparse
import sys
import json

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting multimapping_read_metrics.py")

    # Define inputs
    bam_path = args.bam

    # Define outputs
    output_json_path = args.json

    # Count number of reads that align equally well to more than one position (from NH tag)
    bam = pysam.AlignmentFile(bam_path, "rb")

    total_reads = 0
    multimapping_reads = 0

    for read in bam:
        if read.is_unmapped:
            continue
        total_reads += 1
        if read.has_tag("XA"):
            multimapping_reads += 1

    bam.close()

    # Calculate percentage of multimapping reads
    multimapping_pct = round(multimapping_reads / total_reads * 100, 2)

    # Output to JSON
    result = {
        "bam_file": bam_path,
        "total_reads": {
            "description": "Total number of reads in BAM file",
            "value": total_reads
        },
        "multimapping_reads": {
            "description": "Number of reads that aligned equally well to more than one position",
            "value": multimapping_reads
        },
        "multimapping_pct": {
            "description": "Percentage of total reads that aligned equally well to more than one position",
            "value": multimapping_pct
        }
    }

    with open(output_json_path, 'w') as f:
            json.dump(result, f, indent=4)

    print("[INFO] Completed multimapping_read_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)


