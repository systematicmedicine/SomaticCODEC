#!/usr/bin/env python3
"""
--- ex_duplication_metrics.py ---

Duplication rate calculated from umihistogram data, an output from ex_annotate_bam from ex_create_dsc.smk. 

Duplicates are caused by:
1. Library preparation PCR duplication
2. Flow cell 'PCR' duplication (when both the p5 and p7 strands of the original double stranded molecule bind to different regions of the flow cell)
3. Optical duplicates (optical cross-talk/signal bleed from adjacent spots on the flow cell)

The BAM used for this calculation is the aligned BAM with byproducts removed (correct product only).

The calculation is 1 - (unique reads/total reads). Unique reads are the number of reads with a unique UMI. 

Authors: 
    - James Phie
    - Joshua Johnstone
"""

import pandas as pd
import sys
import json
import argparse

def main(args):
    # Redirect stdout and stderr to the Snakemake log file
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_duplication_metrics.py")

    # Define inputs
    hist_file = args.umi_metrics
    sample = args.sample

    # Define output
    output_json = args.json

    rows = []
    df = pd.read_csv(hist_file, sep="\t")
    unique_reads = int(df.loc[df['family_size'] == 1, 'count'].sum())
    total_reads = int((df['family_size'] * df['count']).sum())
    duplication_rate = round(100 * (1 - unique_reads / total_reads), 2) if unique_reads else 100
    pct_unique_reads = round(100 * (unique_reads / total_reads), 2) if unique_reads else 0

    # Create output JSON object
    output_data = {
        "description": "Duplication rates calculated from umihistogram data",
        "sample": sample,
        "unique_reads": unique_reads,
        "total_reads": total_reads,
        "duplication_rate": duplication_rate,
        "pct_unique_reads": pct_unique_reads
        }

    # Write JSON output
    with open(output_json, "w") as out_f:
        json.dump(output_data, out_f, indent=4)

    # Print script completion message to log
    print("[INFO] Completed ex_duplication_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--umi_metrics", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)