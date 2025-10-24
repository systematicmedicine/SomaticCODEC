# ====================================================================
# ex_snv_distance_metrics.py
#
# For each SNV, calculate the distance to the nearest SNV
# Write a metrics file with percetiles of distances
#
# Authors:
#   - Chat-GPT
#   - Cameron Fraser
# ====================================================================

# Load libraries
import json
import numpy as np
from cyvcf2 import VCF

# Define hard coded variables
PERCENTILES_TO_COMPUTE = [0, 0.1, 1, 2, 5, 10, 25, 50, 75, 90, 95, 98, 99, 99.9, 100]

# Given a VCF path, compute the distribution of distances to the nearest SNV
def calculate_nearest_snv_percentiles(vcf_path):

    positions_by_chrom = {}

    for variant in VCF(vcf_path):
        if variant.is_snp:
            chrom = variant.CHROM
            pos = variant.POS
            positions_by_chrom.setdefault(chrom, []).append(pos)

    all_distances = []

    for chrom, positions in positions_by_chrom.items():
        if len(positions) < 2:
            continue  # No distance to calculate if only one SNV on chromosome

        sorted_pos = sorted(positions)
        for i, pos in enumerate(sorted_pos):
            if i == 0:
                dist = abs(sorted_pos[i + 1] - pos)
            elif i == len(sorted_pos) - 1:
                dist = abs(pos - sorted_pos[i - 1])
            else:
                dist = min(abs(pos - sorted_pos[i - 1]), abs(sorted_pos[i + 1] - pos))
            all_distances.append(dist)

    if not all_distances:
        return {str(p): None for p in PERCENTILES_TO_COMPUTE}
    print(all_distances)
    values = np.percentile(all_distances, PERCENTILES_TO_COMPUTE)
    print(values)
    return {str(p): round(v, 2) for p, v in zip(PERCENTILES_TO_COMPUTE, values)}


# === Snakemake orchestration only ===
if __name__ == "__main__":
    vcf_path = snakemake.input.vcf
    output_path = snakemake.output.metrics_json

    metrics = {
        "description": "Distance to nearest SNV (bp). Only calculated for SNVs that have at least one other SNV on the same chromosome.",
        "percentiles": calculate_nearest_snv_percentiles(vcf_path)
    }

    with open(output_path, "w") as f:
        json.dump(metrics, f, indent=2)