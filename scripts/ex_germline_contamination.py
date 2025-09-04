"""
--- ex_germline_contamination.py

Determines how many called somatic variants are present in dataset of common germline variants

Designed to be used exclusively with the rule "ex_germline_contamination"

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
    print("[INFO] Starting ex_germline_contamination.py")

    # Inputs
    somatic_vcf = Path(snakemake.input.somatic_vcf)
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
            str(intermediate_bgz), str(germline_vcf), "-o", str(germline_matches)],
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

    # --- Calculate percent germline contamination ---
    percent_germline_contamination = round(100 * num_matches / total_variants, 2) if total_variants > 0 else 0

    # --- Write metrics JSON ---
    metrics_file.parent.mkdir(parents=True, exist_ok=True)
    with open(metrics_file, "w") as f:
        json.dump({
            "description": "Number of called somatic variants overlapping known germline variants",
            "somatic_vcf": str(somatic_vcf),
            "germline_vcf": str(germline_vcf),
            "total_variants": total_variants,
            "germline_matches": num_matches,
            "percent_germline_contamination": percent_germline_contamination
        }, f, indent=2)

    print(f"[INFO] Completed ex_germline_contamination.py")

if __name__ == "__main__":
    main(snakemake)
