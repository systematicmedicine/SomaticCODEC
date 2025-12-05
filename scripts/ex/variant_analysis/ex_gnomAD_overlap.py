#!/usr/bin/env python3
"""
--- ex_gnomAD_overlap.py

Determines how many called somatic variants are present in dataset of common germline variants

Designed to be used exclusively with the rule "ex_gnomAD_overlap"

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""
from pathlib import Path
import subprocess
import json
import sys
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
    print("[INFO] Starting ex_gnomAD_overlap.py")

    # Inputs
    somatic_vcf = Path(args.somatic_vcf)
    germline_vcf = Path(args.germline_vcf)

    # Outputs
    intermediate_bgz = Path(args.intermediate_somatic_bgz)
    germline_matches = Path(args.germline_matches)
    metrics_file = Path(args.metrics_file)

    # --- Compress & index somatic VCF ---
    with open(intermediate_bgz, "wb") as out_f, open(args.log, "a") as log_file:
        subprocess.run(["bgzip", "-c", str(somatic_vcf)], stdout=out_f, stderr=log_file, check=True)

    with open(args.log, "a") as log_file:
        subprocess.run(["tabix", "-p", "vcf", str(intermediate_bgz)], stderr=log_file, check=True)

    # --- Count total number of somatic variants ---
    with open(args.log, "a") as log_file:
        result = subprocess.run(
            ["bcftools", "view", "-H", str(somatic_vcf)],
            stdout=subprocess.PIPE,
            text=True,
            stderr=log_file,
            check=True
        )
        total_variants = len(result.stdout.strip().splitlines()) if result.stdout.strip() else 0

    # --- Intersect with gnomAD VCF ---
    germline_matches.parent.mkdir(parents=True, exist_ok=True)
    with open(args.log, "a") as log_file:
        subprocess.run(
            ["bcftools", "isec", "-n=2", "-w1", "-O", "v",
            str(germline_vcf), str(intermediate_bgz), "-o", str(germline_matches)],
            stdout=log_file,
            stderr=log_file,
            check=True
        )

    # --- Count number of gnomAD overlapping SNVs ---
    with open(args.log, "a") as log_file:
        result = subprocess.run(
            ["bcftools", "view", "-H", str(germline_matches)],
            stdout=subprocess.PIPE,
            text=True,
            stderr=log_file,
            check=True
        )
        num_matches = len(result.stdout.strip().splitlines()) if result.stdout.strip() else 0

    # --- Calculate percent gnomAD overlap ---
    percent_gnomAD_overlap = round(100 * num_matches / total_variants, 2) if total_variants > 0 else 0

    # --- Write metrics JSON ---
    metrics_file.parent.mkdir(parents=True, exist_ok=True)
    with open(metrics_file, "w") as f:
        json.dump({
            "description": "Number and rate of called somatic variants that overlapp with known germline variants",
            "somatic_vcf": str(somatic_vcf),
            "gnomAD_vcf": str(germline_vcf),
            "total_somatic_variants": {"description": "Number of called somatic variants",
                                      "value": total_variants},
            "total_gnomAD_matches": {"description": "Number of called somatic variants that overlap with gnomAD",
                                      "value": num_matches},
            "percent_gnomAD_overlap": {"description": "Percentage of called somatic variants that overlap with gnomAD",
                                      "value": percent_gnomAD_overlap},
        }, f, indent=2)

    print(f"[INFO] Completed ex_gnomAD_overlap.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--somatic_vcf", required=True)
    parser.add_argument("--germline_vcf", required=True)
    parser.add_argument("--intermediate_somatic_bgz", required=True)
    parser.add_argument("--intermediate_somatic_tbi", required=True)
    parser.add_argument("--germline_matches", required=True)
    parser.add_argument("--metrics_file", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
