"""
--- ex_somatic_SNV_clustering_metrics.py ---

Calculate percent of positions with somatic SNV clustering (at the same position or within a certain distance)

1. ex_somatic_depth_per_position: Percent of somatic SNVs called that have >1x alt depth
2. ex_somatic_clustered_or_mnv: Percent of somatic SNVs called that are within a set distance of another SNV

Author: James Phie
"""

import sys

# Redirect stdout/stderr to Snakemake log
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")

# Hardcoded variables
CLUSTER_DISTANCE = 150 # SNVs are considered clustered if there are other SNVs within +- CLUSTER_DISTANCE

# Inputs
vcf_snvs = snakemake.input.vcf_snvs
output_metrics = snakemake.output.metrics

# Parse VCF
snv_positions = []
alt_depth_above_1 = 0
alt_depth_above_3 = 0

with open(vcf_snvs) as vcf:
    for line in vcf:
        if line.startswith("#"):
            continue
        fields = line.strip().split("\t")
        chrom = fields[0]
        pos = int(fields[1])
        fmt = fields[8].split(":")
        sample_data = fields[9].split(":")

        # Extract AD (allelic depth)
        if "AD" in fmt:
            ad_index = fmt.index("AD")
            ad_field = sample_data[ad_index]
            try:
                ref_count, alt_count = map(int, ad_field.split(","))
            except ValueError:
                ref_count, alt_count = 0, 0
        else:
            alt_count = 0

        snv_positions.append((chrom, pos))

        if alt_count > 1:
            alt_depth_above_1 += 1
        
        if alt_count > 3:
            alt_depth_above_3 += 1

# Total SNVs
total_snvs = len(snv_positions)

# Metric 1: Percent with alt depth >1
ex_somatic_depth_per_position = (
    100 * alt_depth_above_1 / total_snvs if total_snvs else 0
)

# Metric 2: Clustered SNVs (within +-CLUSTER_DISTANCE base pairs of another SNV)
clustered_snvs = set()

# Sort by chromosome and position
snv_positions.sort()

# Group by chromosome
from collections import defaultdict

chr_pos = defaultdict(list)
for chrom, pos in snv_positions:
    chr_pos[chrom].append(pos)

# For each SNV, check if there’s another SNV within ±CLUSTER_DISTANCE base pairs) 
for chrom, positions in chr_pos.items():
    positions.sort()
    for i in range(len(positions)):
        current_pos = positions[i]
        for j in range(i + 1, len(positions)):
            if positions[j] - current_pos > CLUSTER_DISTANCE:
                break
            clustered_snvs.add((chrom, current_pos))
            clustered_snvs.add((chrom, positions[j]))

ex_somatic_clustered_or_mnv = (
    100 * len(clustered_snvs) / total_snvs if total_snvs else 0
)

# Write output
with open(output_metrics, "w") as out:
    out.write(f"ex_total_somatic_snv_positions\t{total_snvs}\n")
    out.write(f"ex_total_somatic_snv_positions_>1x_depth\t{alt_depth_above_1}\n")
    out.write(f"ex_total_somatic_snv_positions_>3x_depth\t{alt_depth_above_3}\n")
    out.write(f"ex_total_somatic_snv_positions_clustered\t{len(clustered_snvs)}\n")
    out.write(f"ex_somatic_depth_per_position\t{ex_somatic_depth_per_position:.2f}%\n")
    out.write(f"ex_somatic_clustered_or_mnv\t{ex_somatic_clustered_or_mnv:.2f}%\n")

