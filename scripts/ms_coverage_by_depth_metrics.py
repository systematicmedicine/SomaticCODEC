"""
--- ms_coverage_by_depth_metrics.py ---

Calculates the % of the genome covered at various depth thresholds.

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""

import sys
import pandas as pd
import json

def main(snakemake):
    # Redirect stdout/stderr to log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ms_coverage_by_depth_metrics.py")

    # Define inputs
    depth_histogram = snakemake.input.depth_histogram
    sample = snakemake.params.sample
    min_depth = snakemake.params.min_depth

    # Define output
    json_out = snakemake.output.coverage_by_depth

    # Load depth histogram
    df = pd.read_csv(depth_histogram, sep=r"\s+", header=None, names=["count", "depth"])
    df['count'] = df['count'].astype(int)
    df['depth'] = df['depth'].astype(int)

    # Total number of positions
    total_positions = df['count'].sum()

    # Depth thresholds
    thresholds = [1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 200]

    # Compute % genome covered at each threshold
    coverage_dict = {}
    for x in thresholds:
        positions_at_least_x = df[df['depth'] >= x]['count'].sum()
        coverage_dict[f"{x}X"] = round(positions_at_least_x / total_positions * 100, 2)

    pct_coverage_min_depth = coverage_dict[f"{min_depth}X"]

    # Write to JSON
    output = {
    "description": "Percentage of genome covered at each depth threshold",
    "sample": sample,
    "pct_coverage": coverage_dict,
    "defined_min_depth": min_depth,
    "pct_coverage_min_depth": pct_coverage_min_depth
    }

    with open(json_out, "w") as f:
        json.dump(output, f, indent=4)

    print("[INFO] Completed ms_coverage_by_depth_metrics.py")

if __name__ == "__main__":
    main(snakemake)

