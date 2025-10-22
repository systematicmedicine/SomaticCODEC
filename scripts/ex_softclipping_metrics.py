"""
--- ex_softclipping_metrics.py ---

Quantifies how much soft clipping is present in final DSC

Rule to be used exclusively with parent rule, ex_softclipping_metrics

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
import pysam
import json
import numpy as np
import os
import sys

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_total_read_loss.py")

    # Extract soft-clipped base counts per read from a BAM file
    def get_softclip_lengths(bam_path):
        softclip_lengths = []

        with pysam.AlignmentFile(bam_path, "rb") as bam:
            for read in bam:
                if read.cigartuples:
                    softclip_bases = sum(length for op, length in read.cigartuples if op == 4)
                    softclip_lengths.append(softclip_bases)

        return softclip_lengths

    # Return a dict of specified percentiles from a list of values
    def calculate_percentiles(values, percentiles):
        values_array = np.array(values)
        return {
            f"{p}th_percentile": int(np.percentile(values_array, p, method="nearest")) for p in percentiles
        }

    bam_path = snakemake.input.dsc_final
    output_json = snakemake.output.file_path

    softclip_lengths = get_softclip_lengths(bam_path)

    percentiles_to_report = [0, 0.001, 0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9, 99.99, 100]

    if not softclip_lengths:
        percentile_values = {f"{p}th_percentile": 0 for p in percentiles_to_report}
    else:
        percentile_values = calculate_percentiles(softclip_lengths, percentiles_to_report)

    result = {
        "description": (
            "Distribution of soft-clipped bases per read in the final DSC BAM file. "
            "0th and 100th percentile correspond to min and max values."
        ),
        "input_bam": os.path.basename(bam_path),
        "total_reads_processed": len(softclip_lengths),
        "softclip_bases_per_read_percentiles": percentile_values
    }

    with open(output_json, 'w') as f:
        json.dump(result, f, indent=4)

    print("[INFO] Completed ex_total_read_loss.py")

if __name__ == "__main__":
    main(snakemake)
