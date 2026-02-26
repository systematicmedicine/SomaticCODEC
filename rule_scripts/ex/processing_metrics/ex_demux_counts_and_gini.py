#!/usr/bin/env python3
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
import argparse
import helpers.get_metadata as md

def main(args):  

    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_demux_counts_and_gini.py")

    # Calculates Gini coefficient
    def gini_coefficient(x):
        x = np.sort(np.array(x))
        n = len(x)
        cumulative_diffs = np.abs(np.subtract.outer(x, x)).sum()
        return cumulative_diffs / (2 * n**2 * np.mean(x))

    # Get paths
    demux_metrics_path = args.demux_metrics
    json_out_path = args.demux_gini

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

    # Calculate Gini coefficient for ex_samples
    ex_sample_ids = args.ex_sample_ids

    ex_samples_set = set(ex_sample_ids)

    ex_sample_counts = {
        adapter: count
        for adapter, count in adaptor_counts.items()
        if adapter in ex_samples_set
        } 

    gini_coefficient_ex_samples = round(gini_coefficient(list(ex_sample_counts.values())), 3)

    # Collate counts, percentages, and Gini coefficient
    output_data = {
        "description": (
            "Summary of adaptor counts for ex samples and ex technical controls.",
            "Gini coefficient for inequality between ex_samples"
        ),
        "total_input_pairs": total_input_pairs,
        "total_pairs_demuxed": total_pairs_demuxed,
        "pct_reads_lost_demux": pct_reads_lost_demux,
        "adaptor_counts": dict(adaptor_counts),
        "adaptor_percentages": adaptor_percentages,
        "gini_coefficient": gini_coefficient_ex_samples
    }

    # Write to JSON
    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    print("[INFO] Completed ex_demux_counts_and_gini.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--demux_metrics", required=True)
    parser.add_argument("--demux_gini", required=True)
    parser.add_argument("--ex_sample_ids", required=True, nargs="+")
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)










