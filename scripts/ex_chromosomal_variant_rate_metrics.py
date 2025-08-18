"""
--- ex_chromosomal_variant_rate_metrics.py ---

Calculates Gini coefficient for difference in somatic variant rate between chromosomes.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import numpy as np
from collections import defaultdict
import json
import sys

def main(snakemake):
    # Initiate logging
    sys.stdout = open(snakemake.log[0], "a")
    sys.stderr = open(snakemake.log[0], "a")
    print("[INFO] Starting ex_chromosomal_variant_rate_metrics.py")

    # Calculates Gini coefficient
    def gini_coefficient(x):
        x = np.sort(np.array(x))
        n = len(x)
        cumulative_diffs = np.abs(np.subtract.outer(x, x)).sum()
        return cumulative_diffs / (2 * n**2 * np.mean(x))

    # Get paths
    vcf_path = snakemake.input.vcf
    fai_path = snakemake.input.fai
    json_out_path = snakemake.output.metrics

    # Load chromosome lengths from FAI
    chrom_lengths = {}
    with open(fai_path, "r") as f:
        for line in f:
            fields = line.strip().split("\t")
            chrom, length = fields[0], int(fields[1])
            chrom_lengths[chrom] = length

    # Count variants per chromosome
    chrom_counts = defaultdict(int)
    with open(vcf_path, "r") as f:
        for line in f:
            if line.startswith("#"):
                continue
            chrom = line.split("\t", 1)[0]
            chrom_counts[chrom] += 1

    # Calculate variant rates per chromosome
    chrom_rates = {}
    for chrom, length in chrom_lengths.items():
        count = chrom_counts.get(chrom, 0)
        if length and length > 0:
            chrom_rates[chrom] = count / length
        else:
            print(f"[WARN] Chromosome {chrom} has invalid length in FAI. Skipping rate calculation.")
            chrom_rates[chrom] = None

    # Collate per-chromosome data (now guaranteed to include all chromosomes in FAI)
    chrom_data = {}
    for chrom in chrom_lengths.keys():
        chrom_data[chrom] = {
            "variant_count": chrom_counts.get(chrom, 0),
            "variant_rate": round(chrom_rates[chrom], 8)
        }

    valid_rates = [r for r in chrom_rates.values() if r is not None]

    # Collate counts, rates, and calculate Gini coefficient
    output_data = {
    "description": (
        "Number/rate of somatic variants per chromosome, and Gini coefficient for inequality in variant rates."
    ),
    "chromosomes": chrom_data,
    "gini_coefficient": round(gini_coefficient(valid_rates), 3) if valid_rates else None
    }

    # Write to JSON
    with open(json_out_path, "w") as out_f:
        json.dump(output_data, out_f, indent=4)


    print("[INFO] Completed ex_chromosomal_variant_rate_metrics.py")

if __name__ == "__main__":
    main(snakemake)

