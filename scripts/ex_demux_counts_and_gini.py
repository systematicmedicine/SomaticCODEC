"""
--- ex_demux_counts_and_gini.py ---

Generates a summary file with adaptor counts and the Gini coefficient for inequality between adaptors

To be used with rule ex_demux_counts_and_gini

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import numpy as np
import re
from collections import defaultdict
import json
import sys

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_demux_counts_and_gini.py")

    # Calculates Gini coefficient
    def gini_coefficient(x):
        x = np.sort(np.array(x))
        n = len(x)
        cumulative_diffs = np.abs(np.subtract.outer(x, x)).sum()
        return cumulative_diffs / (2 * n**2 * np.mean(x))

    # Get paths
    demux_metrics_path = snakemake.input.demux_metrics
    json_out_path = snakemake.output.demux_gini

    # Get input count and counts for each adaptor after demux
    adaptor_counts = defaultdict(int)
    with open(demux_metrics_path, "r") as f:
            for line in f:
                total_match = re.search(r"Total read pairs processed:\s+([\d,]+)", line)
                if total_match:
                    total_input_pairs = int(total_match.group(1).replace(",", ""))
                
                adapter_match = re.search(r"=== .* read: Adapter ([^=]+) ===", line)
                if adapter_match:
                    current_adapter = adapter_match.group(1)
                    continue

                trimmed_match = re.search(r"Trimmed:\s+([\d,]+) times", line)
                if trimmed_match and current_adapter:
                    count = int(trimmed_match.group(1).replace(",", ""))
                    adaptor_counts[current_adapter] += count

        # Calculate total trimmed reads
    total_pairs_demuxed = sum(adaptor_counts.values()) / 2

    # Calculate percentage of reads lost to demux
    pct_reads_lost_demux = round(100 * (1 - total_pairs_demuxed / total_input_pairs), 2)

    # Calculate percentage of total trimmed reads per adapter
    adaptor_percentages = {}
    if total_pairs_demuxed > 0:
        for adapter, count in adaptor_counts.items():
            adaptor_percentages[adapter] = round(((count / 2) / total_pairs_demuxed) * 100, 2)
    else:
        # Avoid division by zero if no trimmed reads found
        for adapter in adaptor_counts.keys():
            adaptor_percentages[adapter] = 0.0

    # Collate counts, percentages, and calculate Gini coefficient
    output_data = {
        "description": (
            "Summary of adaptor counts and Gini coefficient for inequality between counts."
        ),
        "total_input_pairs": total_input_pairs,
        "total_pairs_demuxed": total_pairs_demuxed,
        "pct_reads_lost_demux": pct_reads_lost_demux,
        "adaptor_counts": dict(adaptor_counts),
        "adaptor_percentages": adaptor_percentages,
        "gini_coefficient": round(gini_coefficient(list(adaptor_counts.values())), 3)
    }

    # Write to JSON
    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_demux_metrics_gini.py")

# Only run in Snakemake
if __name__ == "__main__":
    main(snakemake) 







