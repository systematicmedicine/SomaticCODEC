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

"""
# Import libraries
import sys
import pysam

# Redirect stdout/stderr to Snakemake log
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")

# Define hard coded variables
QUALITY_THRESHOLD = 70

# Inputs from Snakemake
bam = snakemake.input.bam
bed = snakemake.input.bed
metrics = snakemake.output.metrics

bamfile = pysam.AlignmentFile(bam, "rb")

# Load BED regions into list of (chrom, start, end)
regions = []
with open(bed) as f:
    for line in f:
        chrom, start, end = line.strip().split()[:3]
        regions.append((chrom, int(start), int(end)))

# Total positions in the bed file 
bed_total_positions = sum(end - start for _, start, end in regions)

# Total positions in the entire genome (extracted from the reference genome)
ref_lengths = dict(zip(bamfile.references, bamfile.lengths))
total_genome_positions = sum(ref_lengths.values())

# Calculate coverage (total positions with >0x depth), and depth (total bases at all positions/total number of positions)
bed_total_depth = 0
bed_covered_positions = 0

for chrom, start, end in regions:
    for pileupcolumn in bamfile.pileup(chrom, start, end, stepper="all", min_base_quality=0, truncate=True):
        q_depth = sum(
            1 for pileupread in pileupcolumn.pileups
            if (
                not pileupread.is_del and
                not pileupread.is_refskip and
                pileupread.query_position is not None and
                pileupread.alignment.query_qualities[pileupread.query_position] >= QUALITY_THRESHOLD
            )
        )
        bed_total_depth += q_depth
        if q_depth > 0:
            bed_covered_positions += 1

# Total duplex depth in BED-covered regions of the genome
ex_mean_analyzable_duplex_depth = bed_total_depth / bed_total_positions if bed_total_positions else 0

# BED-covered positions with >0x duplex depth (as % of all BED positions)
ex_dsc_coverage_bedregions = 100 * bed_covered_positions / bed_total_positions if bed_total_positions else 0

# BED-covered positions with >0x duplex depth (as % of entire genome - ie. total coverage of genome for variant calling)
ex_dsc_coverage_wholegenome = 100 * bed_covered_positions / total_genome_positions if total_genome_positions else 0

# BED region as % of genome
include_bed_coverage = 100 * bed_total_positions / total_genome_positions if total_genome_positions else 0

# Total duplex bases with Q≥ required Q score (typically 70) in BED regions
duplex_bases_in_bed_positions = bed_total_depth

bamfile.close()

# Write metrics
with open(metrics, "w") as f:
    f.write(f"total_genome_positions\t{total_genome_positions}\n")
    f.write(f"bed_total_positions\t{bed_total_positions}\n")
    f.write(f"include_bed_coverage\t{include_bed_coverage:.2f}%\n")
    f.write(f"ex_mean_analyzable_duplex_depth\t{ex_mean_analyzable_duplex_depth:.4f}\n")
    f.write(f"ex_dsc_coverage_bedregions\t{ex_dsc_coverage_bedregions:.2f}%\n")
    f.write(f"ex_dsc_coverage_wholegenome\t{ex_dsc_coverage_wholegenome:.2f}%\n")
    f.write(f"duplex_bases_in_bed_positions\t{duplex_bases_in_bed_positions}\n")
