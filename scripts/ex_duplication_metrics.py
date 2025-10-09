"""
--- ex_duplication_metrics.py ---

Duplication rate calculated from umi_tools dedup data, an output from ex_group_by_umi.

Duplicates are caused by:
1. Library preparation PCR duplication
2. Flow cell 'PCR' duplication (when both the p5 and p7 strands of the original double stranded molecule bind to different regions of the flow cell)
3. Optical duplicates (optical cross-talk/signal bleed from adjacent spots on the flow cell)

The BAM used for this calculation is the aligned BAM with correct product, mapped, and primary alignments only.

The calculation is 1 - (unique reads/total reads). Unique reads are the number of reads with a unique UMI. 

Authors: 
    - James Phie
    - Joshua Johnstone
    - Chat-GPT
"""

import sys
import json
import re

def main(snakemake):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_duplication_metrics.py")

    # Define inputs
    umi_metrics_path = snakemake.input.umi_metrics
    sample = snakemake.params.sample

    # Define output
    output_json = snakemake.output.json

    # Read umi metrics
    with open(umi_metrics_path) as f:
        content = f.read()

    # Extract read counts
    input_reads = int(re.search(r'Input Reads: (\d+)', content).group(1))
    output_reads = int(re.search(r'Number of reads out: (\d+)', content).group(1))

    duplication_rate = round(1 - output_reads / input_reads, 4)

    # Prepare JSON
    metrics_dict = {
        "Description:": "Duplication rate based on UMItools dedup metrics",
        "sample": sample,
        "input_reads": input_reads,
        "deduplicated_reads": output_reads,
        "duplication_rate": duplication_rate
    }

    # Write JSON
    with open(output_json, "w") as out:
        json.dump(metrics_dict, out, indent=4)

    print("[INFO] Completed ex_duplication_metrics.py")

if __name__ == "__main__":
    main(snakemake)