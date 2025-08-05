"""
--- ex_dsc_coverage_metrics.py ---

Calculate duplex sequencing coverage metrics:

1. Mean analyzable duplex depth across variant calling regions (selected per sample with include_bed)
2. Percent of variant calling positions with >0x coverage (selected per sample with include_bed)
3. Percent of whole genome positions with >0x coverage

Only bases with high base quality scores (>= QUALITY_THRESHOLD, typically >=Q70) are considered for depth and coverage calculations (e.g. duplex bases made from 2 Q35 bases).

Inputs:
- Filtered DSC BAM file
- Include BED file which excludes difficult to call regions (GIAB difficult regions), low depth germline regions, and germline mutations

Authors: 
    - James Phie
    - Joshua Johnstone
"""
# Import libraries
import sys
import pysam
import subprocess

# Redirect stdout/stderr to Snakemake log
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")

# Define hard coded variables
QUALITY_THRESHOLD = 70

# Inputs from Snakemake
bam = snakemake.input.bam
include_bed = snakemake.input.include_bed
lowdepth_bed = snakemake.input.lowdepth_bed
ref_fai = snakemake.input.fai
metrics = snakemake.output.metrics

bamfile = pysam.AlignmentFile(bam, "rb")

# Load BED regions into list of (chrom, start, end)
regions = []
with open(include_bed) as f:
    for line in f:
        chrom, start, end = line.strip().split()[:3]
        regions.append((chrom, int(start), int(end)))

# Total positions in the bed file 
include_bed_total_positions = sum(end - start for _, start, end in regions)

# Total positions in the entire genome (extracted from the reference genome)
ref_lengths = dict(zip(bamfile.references, bamfile.lengths))
total_genome_positions = sum(ref_lengths.values())

bamfile.close()

# Extract MS genomic positions with >30x depth
ms_30x_depth = subprocess.run(
    ("bedtools", "complement", "-i", lowdepth_bed, "-g", ref_fai),
    capture_output=True, 
    text=True
)

ms_covered_positions = set()
for line in ms_30x_depth.stdout.strip().splitlines():
    chrom, start, end = line.strip().split()[:3]
    start, end = int(start), int(end)
    ms_covered_positions.update((chrom, pos) for pos in range(start + 1, end + 1)) 

# Extract DSC positions with >0x depth and quality score over threshold
ex_depth_qual = subprocess.run(
    ("samtools", "depth", "-q", str(QUALITY_THRESHOLD), bam),
    capture_output=True, 
    text=True
)

ex_covered_positions = set()
for line in ex_depth_qual.stdout.strip().splitlines():
    chrom, pos, depth = line.strip().split()[:3]
    ex_covered_positions.add((chrom, int(pos)))

# Calculate coverage overlap between MS (>30x depth) and EX (>0x depth and quality score over threshold)
overlapping_positions = ms_covered_positions & ex_covered_positions
all_covered_positions = ms_covered_positions | ex_covered_positions
num_overlap = len(overlapping_positions)
num_union = len(all_covered_positions)

coverage_overlap_ex_ms = (num_overlap / num_union) * 100 if num_union else 0

# Calculate DSC depth at each include BED position
ex_depth_in_bed = subprocess.run(
    ("samtools", "depth", "-q", str(QUALITY_THRESHOLD), "-b", include_bed, bam),
    capture_output=True, 
    text=True
)

include_bed_total_depth = 0
include_bed_covered_positions = 0

for line in ex_depth_in_bed.stdout.strip().split("\n"):
    if line:
        chrom, pos, depth = line.strip().split()
        depth = int(depth)
        include_bed_total_depth += depth
        if depth > 0:
            include_bed_covered_positions += 1

# BED region as % of genome
include_bed_coverage = 100 * include_bed_total_positions / total_genome_positions if total_genome_positions else 0

# Total duplex depth in BED-covered regions of the genome
ex_mean_analyzable_duplex_depth = include_bed_total_depth / include_bed_total_positions if include_bed_total_positions else 0

# BED-covered positions with >0x duplex depth (as % of all BED positions)
ex_dsc_coverage_bedregions = 100 * include_bed_covered_positions / include_bed_total_positions if include_bed_total_positions else 0

# BED-covered positions with >0x duplex depth (as % of entire genome - ie. total coverage of genome for variant calling)
ex_dsc_coverage_wholegenome = 100 * include_bed_covered_positions / total_genome_positions if total_genome_positions else 0

# Total duplex bases with Q≥ required Q score (typically 70) in BED regions
duplex_bases_in_bed_positions = include_bed_total_depth

# Write metrics
with open(metrics, "w") as f:
    f.write(f"total_genome_positions\t{total_genome_positions}\n")
    f.write(f"bed_total_positions\t{include_bed_total_positions}\n")
    f.write(f"coverage_overlap_ex_ms\t{coverage_overlap_ex_ms:.2f}%\n")
    f.write(f"include_bed_coverage\t{include_bed_coverage:.2f}%\n")
    f.write(f"ex_mean_analyzable_duplex_depth\t{ex_mean_analyzable_duplex_depth:.4f}\n")
    f.write(f"ex_dsc_coverage_bedregions\t{ex_dsc_coverage_bedregions:.2f}%\n")
    f.write(f"ex_dsc_coverage_wholegenome\t{ex_dsc_coverage_wholegenome:.2f}%\n")
    f.write(f"duplex_bases_in_bed_positions\t{duplex_bases_in_bed_positions}\n")
