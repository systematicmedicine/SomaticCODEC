"""
--- ex_duplex_overlap_metrics.py ---

Calculates the overlap between R1 and R2 for each duplex consensus sequence, and outputs overlap length percentiles.

To be used with rule ex_duplex_overlap_metrics

Authors: 
    - Joshua Johnstone
"""

import sys
import json
import pysam
import numpy as np

def main(snakemake):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_duplex_overlap_metrics.py")

    # Define inputs
    dsc_bam = snakemake.input.bam

    # Define input path
    json_out_path = snakemake.output.metrics

    overlap_lengths = []

    for read in pysam.AlignmentFile(dsc_bam, "rb"):

        # Get depths for R1 and R2 at each duplex position
        r1_depths = read.get_tag("ad") 
        r2_depths = read.get_tag("bd")

        # Calculate number of duplex positions where both R1 and R2 had depth > 0
        overlap_length = sum(1 for r1, r2 in zip(r1_depths, r2_depths) if r1 > 0 and r2 > 0)

        # Append to list of overlap lengths
        overlap_lengths.append(overlap_length)

    # Calculate overlap length percentiles
    percentiles = [0, 1, 2.5, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 98.5, 99, 100]
    overlap_percentiles = {str(p): float(np.percentile(overlap_lengths, p)) for p in percentiles}

    # Output data to JSON
    output_data = {
        "overlap_percentiles": {
            "description": "Percentiles for length of overlap between R1 and R2 bases in duplex consensus sequence",
            "value": overlap_percentiles
        }
    }

    with open(json_out_path, "w") as out:
        json.dump(output_data, out, indent=4)

    print("[INFO] Completed ex_duplex_overlap_metrics.py")

# Run in Snakemake
if __name__ == "__main__":
    main(snakemake) 