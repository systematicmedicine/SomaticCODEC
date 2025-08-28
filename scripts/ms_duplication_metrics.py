"""
--- ms_duplication_metrics.py ---

Calculates duplication rate based on UMItools dedup metrics.

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import re
import sys
from pathlib import Path
import json

def main(snakemake):
    # Redirect stdout/stderr to log
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ms_duplication_metrics.py")

    # Define inputs
    dedup_metrics = snakemake.input.dedup_metrics
    sample = snakemake.params.sample

    # Define output
    json_out = snakemake.output.duplication_metrics

    # Read dedup metrics
    with open(dedup_metrics) as f:
        content = f.read()

    # Extract read counts
    input_reads = int(re.search(r'Input Reads: (\d+)', content).group(1))
    r1_unmapped = int(re.search(r'Read 1 unmapped: (\d+)', content).group(1))
    r2_unmapped = int(re.search(r'Read 2 unmapped: (\d+)', content).group(1))
    mapped_reads = input_reads - (r1_unmapped + r2_unmapped)
    output_reads = int(re.search(r'Number of reads out: (\d+)', content).group(1))

    duplication_rate = round(1 - output_reads / mapped_reads, 4)

    # Prepare JSON
    metrics_dict = {
        "Description:": "Duplication rate based on UMItools dedup metrics",
        "sample": sample,
        "input_reads": input_reads,
        "mapped_input_reads": mapped_reads,
        "deduplicated_reads": output_reads,
        "duplication_rate": duplication_rate
    }

    # Write JSON
    with open(json_out, "w") as out:
        json.dump(metrics_dict, out, indent=4)

    print("[INFO] Completed ms_duplication_metrics.py")

if __name__ == "__main__":
    main(snakemake)
