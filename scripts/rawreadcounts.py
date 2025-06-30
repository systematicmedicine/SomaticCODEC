"""
--- rawreadcounts.py ---

Calculates the number and percentage of raw read pairs that demultiplexed to each sample. 

Author: James Phie
"""

import json
import pandas as pd

# Inputs from Snakemake
json_path = snakemake.input.json
output_path = snakemake.output.readcounts
fasta_path = snakemake.params.fasta  # Not used currently, but preserved for future use
lane = snakemake.wildcards.ex_lane
df = snakemake.params.used

# Validate lane exists
if lane not in df["lane"].unique():
    raise ValueError(f"Lane '{lane}' not found in ex_samples.csv.")

# Extract expected samples from this lane
used_samples = sorted(df[df["lane"] == lane]["ex_sample"])

# Load demux JSON
with open(json_path) as f:
    report = json.load(f)

# Total read pairs (before processing)
total_reads = report["read_counts"]["input"]

# Read pairs with both adapters present
demuxed_read_pairs = min(
    report["read_counts"].get("read1_with_adapter", 0),
    report["read_counts"].get("read2_with_adapter", 0)
)

# Tally matches from adapters_read1 and adapters_read2
match_counts = {}
for entry in report.get("adapters_read1", []) + report.get("adapters_read2", []):
    name = entry["name"]
    if name in used_samples:
        match_counts[name] = match_counts.get(name, 0) + entry["total_matches"]

# Convert to read pairs (each match is one read, not a pair)
read_pair_counts = {name: count // 2 for name, count in match_counts.items()}

# Ensure all expected samples appear in output
with open(output_path, "w") as out:
    out.write("Sample\tRead pairs per sample\tPercentage of demuxed\tPercentage of raw reads\n")
    for sample in used_samples:
        count = read_pair_counts.get(sample, 0)
        pct_demuxed = 100 * count / demuxed_read_pairs if demuxed_read_pairs > 0 else 0
        pct_total = 100 * count / total_reads if total_reads > 0 else 0
        out.write(f"{sample}\t{count}\t{pct_demuxed:.4f}%\t{pct_total:.4f}%\n")