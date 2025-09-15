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
import pandas as pd
import sys
from cyvcf2 import VCF

# Logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_snv_distance_metrics.py")

# Snakemake parameter injection
vcf_path = snakemake.input.vcf
output_path = snakemake.output.metrics_json

# Load SNVs from VCF
positions_by_chrom = {}
for variant in VCF(vcf_path):
    if variant.is_snp:
        chrom = variant.CHROM
        pos = variant.POS
        positions_by_chrom.setdefault(chrom, []).append(pos)

# alculate nearest distances
all_distances = []

for chrom, positions in positions_by_chrom.items():
    if len(positions) < 2:
        continue  # Can't calculate distances if only one SNV on this chromosome

    sorted_pos = sorted(positions)
    for i, pos in enumerate(sorted_pos):
        if i == 0:
            dist = abs(sorted_pos[i+1] - pos)
        elif i == len(sorted_pos) - 1:
            dist = abs(pos - sorted_pos[i-1])
        else:
            dist = min(abs(pos - sorted_pos[i-1]), abs(sorted_pos[i+1] - pos))
        all_distances.append(dist)

# Handle edge case: no distances
if not all_distances:
    metrics = {
        "description": "Distance to nearest SNV (bp). Only calculated for SNVs that have at least one other SNV on the same chromosome.",
        "percentiles": {str(p): None for p in [0, 0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9, 100]}
    }
else:
    percentiles = [0, 0.1, 1, 5, 10, 25, 50, 75, 90, 95, 99, 99.9, 100]
    values = np.percentile(all_distances, percentiles)

    metrics = {
        "description": "Distance to nearest SNV (bp). Only calculated for SNVs that have at least one other SNV on the same chromosome.",
        "percentiles": {
            f"{p}": round(v, 2) for p, v in zip(percentiles, values)
        }
    }

# Write output
with open(output_path, "w") as f:
    json.dump(metrics, f, indent=2)

# Finished script message
print("[INFO] Finishing ex_snv_distance_metrics.py")