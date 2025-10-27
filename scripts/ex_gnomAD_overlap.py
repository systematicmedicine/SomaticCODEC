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

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_gnomAD_overlap.py")

    # Inputs
    somatic_vcf = Path(snakemake.input.somatic_vcf)
    somatic_all_vcf = Path(snakemake.input.somatic_all_vcf)
    germline_vcf = Path(snakemake.input.germline_vcf)

    # Outputs
    intermediate_bgz = Path(snakemake.output.intermediate_somatic_bgz)
    germline_matches = Path(snakemake.output.germline_matches)
    metrics_file = Path(snakemake.output.metrics_file)

    # --- Compress & index somatic VCF ---
    with open(intermediate_bgz, "wb") as out_f, open(snakemake.log[0], "a") as log_file:
        subprocess.run(["bgzip", "-c", str(somatic_vcf)], stdout=out_f, stderr=log_file, check=True)

    with open(snakemake.log[0], "a") as log_file:
        subprocess.run(["tabix", "-p", "vcf", str(intermediate_bgz)], stderr=log_file, check=True)

    # --- Count total number of somatic variants ---
    with open(snakemake.log[0], "a") as log_file:
        result = subprocess.run(
            ["bcftools", "view", "-H", str(somatic_vcf)],
            stdout=subprocess.PIPE,
            text=True,
            stderr=log_file,
            check=True
        )
        total_variants = len(result.stdout.strip().splitlines()) if result.stdout.strip() else 0

    # --- Intersect with germline VCF ---
    germline_matches.parent.mkdir(parents=True, exist_ok=True)
    with open(snakemake.log[0], "a") as log_file:
        subprocess.run(
            ["bcftools", "isec", "-n=2", "-w1", "-O", "v",
            str(germline_vcf), str(intermediate_bgz), "-o", str(germline_matches)],
            stdout=log_file,
            stderr=log_file,
            check=True
        )

    # --- Count number of germline matches ---
    with open(snakemake.log[0], "a") as log_file:
        result = subprocess.run(
            ["bcftools", "view", "-H", str(germline_matches)],
            stdout=subprocess.PIPE,
            text=True,
            stderr=log_file,
            check=True
        )
        num_matches = len(result.stdout.strip().splitlines()) if result.stdout.strip() else 0

    # --- Count number of bases assessable for somatic calling ---
    evaluated_bases = 0

    with open(somatic_all_vcf) as f:
    # Check through all lines of the complete vcf (variants and no variants) for the following:
        # Evaluated bases - total bases assessed for variants (ie. denominator)
        for line in f:
            if line.startswith("#"):
                continue

            cols = line.strip().split("\t")
            assert len(cols) >= 9, f"Malformed line with too few columns:\n{line}"

            sample_fmt = cols[8].split(":")
            sample_vals = cols[9].split(":")
            fmt = dict(zip(sample_fmt, sample_vals))
            dp_fmt = int(fmt.get("DP", 0))

            if dp_fmt > 0:
                evaluated_bases += 1

    # --- Calculate percent gnomAD overlap ---
    percent_gnomAD_overlap = round(100 * num_matches / total_variants, 2) if total_variants > 0 else 0

    # --- Calculate rate of gnomAD overlap ---
    rate_gnomAD_overlap = round(num_matches / evaluated_bases, 10) if evaluated_bases > 0 else 0

    # --- Write metrics JSON ---
    metrics_file.parent.mkdir(parents=True, exist_ok=True)
    with open(metrics_file, "w") as f:
        json.dump({
            "description": "Number and rate of called somatic variants that overlapp with known germline variants",
            "somatic_vcf": str(somatic_vcf),
            "gnomAD_vcf": str(germline_vcf),
            "total_evaluated_bases": {"description": "Number of unmasked bases with DP > 0 and BQ > min_base_quality",
                                      "value": evaluated_bases},
            "total_somatic_variants": {"description": "Number of called somatic variants",
                                      "value": total_variants},
            "total_gnomAD_matches": {"description": "Number of called somatic variants that overlap with gnomAD",
                                      "value": num_matches},
            "percent_gnomAD_overlap": {"description": "Percentage of called somatic variants that overlap with gnomAD",
                                      "value": percent_gnomAD_overlap},
            "rate_gnomAD_overlap": {"description": "Rate of SNVs that overlap with gnomAD per evalulated base",
                                      "value": rate_gnomAD_overlap},
        }, f, indent=2)

    print(f"[INFO] Completed ex_gnomAD_overlap.py")

if __name__ == "__main__":
    main(snakemake)
