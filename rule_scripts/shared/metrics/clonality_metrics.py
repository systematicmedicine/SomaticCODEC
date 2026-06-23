#!/usr/bin/env python3
"""
--- clonality_metrics.py ---

Generates clonality metrics for an input VCF.

Authors:
    - Joshua Johnstone
"""
import sys
import argparse
import json

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting clonality_metrics.py")

    # Define input and output paths
    input_vcf = args.vcf
    output_json = args.json

    # Count unique and total SNVs
    unique_snvs = 0
    clonal_snvs = 0

    with open(input_vcf, "r") as vcf:
        for line in vcf:

            # Skip header lines
            if line.startswith("#"):
                continue  

            # Extract format values
            cols = line.strip().split("\t")
            assert len(cols) >= 9, f"Malformed line with too few columns:\n{line}"
            sample_fmt = cols[8].split(":")
            sample_vals = cols[9].split(":")
            fmt = dict(zip(sample_fmt, sample_vals))

            # Get alt allele depth
            ad_vals = [int(x) for x in fmt.get("AD", "").split(",")]
            alt_ad = sum(ad_vals[1:]) if len(ad_vals) > 1 else 0

            # Count unique and clonal SNVs
            if alt_ad == 0:
                continue
            elif alt_ad == 1:
                unique_snvs += 1
            elif alt_ad > 1:
                clonal_snvs += alt_ad

    # Calculate clonality metrics
    total_snvs = unique_snvs + clonal_snvs
    pct_unique_snvs = round((unique_snvs / total_snvs) * 100, ndigits = 2) if total_snvs > 0 else 0
    pct_clonal_snvs = round((clonal_snvs / total_snvs) * 100, ndigits = 2) if total_snvs > 0 else 0

    # Write to output JSON
    results = {
        "total_snvs": {
            "value": total_snvs,
            "description": "Sum total of ALT allele depth for all variants in the VCF."
        },
        "unique_snvs": {
            "value": unique_snvs,
            "description": "Number of variants with ALT allele depth = 1."
        },
        "pct_unique_snvs": {
            "value": pct_unique_snvs,
            "description": "Percentage of total variants with ALT allele depth = 1."
        },
        "clonal_snvs": {
            "value": clonal_snvs,
            "description": "Number of variants with ALT allele depth > 1."
        },
        "pct_clonal_snvs": {
            "value": pct_clonal_snvs,
            "description": "Percentage of total variants with ALT allele depth > 1."
        }
    }

    with open(output_json, "w") as out:
        json.dump(results, out, indent=4)

    print("[INFO] Completed clonality_metrics.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--vcf", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)