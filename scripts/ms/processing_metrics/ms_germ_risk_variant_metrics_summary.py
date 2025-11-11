#!/usr/bin/env python3
"""
--- ms_germ_risk_variant_metrics_summary.py ---

Generates a summary file with key germline risk metrics

To be used with rule ms_germ_risk_variant_metrics_summary

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pandas as pd
import json
from collections import defaultdict
import sys
import subprocess
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ms_germ_risk_variant_metrics_summary.py")

    # Parses bcftools stats output into a dictionary of dataframes
    def parse_bcftools_stats(file_path):
        sections = defaultdict(list)

        with open(file_path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split("\t")
                section_key = parts[0]
                sections[section_key].append(parts[1:])

        # Convert lists to DataFrames
        for key in sections:
            max_len = max(len(row) for row in sections[key])
            padded_data = [row + [''] * (max_len - len(row)) for row in sections[key]]
            sections[key] = pd.DataFrame(padded_data)

        return sections

    # Load sample name
    sample = args.sample

    # Define input paths
    variant_metrics_path = args.variant_metrics
    pileup_bcf = args.pileup_bcf

    # Define min_depth param
    min_depth = args.min_depth

    # Define output path
    output_json = args.summary

    # Get each section of bcftools stats output
    sections = parse_bcftools_stats(variant_metrics_path)

    # Calculate number of bases eligible for variant calling (depth > min_depth, quality > min_BQ)
    with open(args.log, "a") as log_file:
        proc = subprocess.Popen(
            ["bcftools", "view", "--include", f"FMT/DP>={min_depth}", str(pileup_bcf)],
            stdout=subprocess.PIPE,
            stderr=log_file,
            text=True)
        
        callable_bases = sum(1 for line in proc.stdout if not line.startswith("#"))
        proc.wait()
   
    # Pull out key metrics and output in json
    variants_called = int(sections["SN"].loc[sections["SN"][1] == "number of records:", 2].values[0])

    germline_variant_rate = round(variants_called / callable_bases, 4) if callable_bases else 0
    
    snv_indel_ratio = round(int(sections["SN"].loc[sections["SN"][1] == "number of SNPs:", 2].values[0]) / int(sections["SN"].loc[sections["SN"][1] == "number of indels:", 2].values[0]), 2)

    insertion_deletion_ratio = round(sections["IDD"][sections["IDD"][1].astype(int) > 0][2].astype(int).sum() / sections["IDD"][sections["IDD"][1].astype(int) < 0][2].astype(int).sum(), 2)

    MNP_other_variants = int(sections["SN"].loc[sections["SN"][1] == "number of MNPs:", 2].values[0]) + int(sections["SN"].loc[sections["SN"][1] == "number of others:", 2].values[0])

    transition_transversion_ratio = round(float(sections["TSTV"].iloc[0][3]), 2)

    result = {
    "description": (
        "Summary of key candidate variant metrics (see component metrics csv for definitions)"
    ),
    "sample": sample,
    "candidiate_variant_metrics_file": variant_metrics_path,
    "callable_bases": callable_bases,
    "variants_called": variants_called,
    "germline_variant_rate": germline_variant_rate,
    "snv_indel_ratio": snv_indel_ratio,
    "insertion_deletion_ratio": insertion_deletion_ratio,
    "MNP_other_variants": MNP_other_variants,
    "transition_transversion_ratio": transition_transversion_ratio,
    }

    with open(output_json, 'w') as f:
        json.dump(result, f, indent=4)

    print("[INFO] Completed ms_germ_risk_variant_metrics_summary.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant_metrics", required=True)
    parser.add_argument("--pileup_bcf", required=True)
    parser.add_argument("--summary", required=True)
    parser.add_argument("--min_depth", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)