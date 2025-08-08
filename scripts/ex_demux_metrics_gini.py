"""
--- ex_demux_metrics_gini.py ---

Generates a summary file with the Gini coefficient of demultiplexed sample read count

To be used with rule ex_demux_metrics_gini

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import numpy as np
import re
from collections import defaultdict
import json

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_demux_metrics_gini.py")

# Calculates Gini coefficient
def gini_coefficient(x):
    x = np.sort(np.array(x))
    n = len(x)
    cumulative_diffs = np.abs(np.subtract.outer(x, x)).sum()
    return cumulative_diffs / (2 * n**2 * np.mean(x))

# Get paths
demux_metrics_path = snakemake.input.demux_metrics
json_out_path = snakemake.output.demux_gini

# Get counts for each adaptor after demux
trimmed_counts = defaultdict(int)
with open(demux_metrics_path, "r") as f:
        for line in f:
            adapter_match = re.match(r"=== .* read: Adapter (S\d+) ===", line)
            if adapter_match:
                current_adapter = adapter_match.group(1)
                continue

            trimmed_match = re.search(r"Trimmed:\s+([\d,]+) times", line)
            if trimmed_match and current_adapter:
                count = int(trimmed_match.group(1).replace(",", ""))
                trimmed_counts[current_adapter] += count

# Collate counts and calculate Gini coefficient
output_data = {
     "description": (
    "Summary of adaptor counts and Gini coefficient for inequality between counts."
    ),
    "trimmed_counts": dict(trimmed_counts),
    "gini_coefficient": round(gini_coefficient(list(trimmed_counts.values())), 3)
}

# Write to JSON
with open(json_out_path, "w") as out_f:
    json.dump(output_data, out_f, indent=4)

print("[INFO] Completed ex_demux_metrics_gini.py")








