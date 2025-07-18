"""
--- ex_dsc_remap_metrics.py ---

Extract basic realignment metrics from the double stranded consensus bam.

1. Percentage of total reads which successfully aligned to the reference genome
2. Percentage of total reads with a mapQ score of at least 60. 

Author: James Phie
"""
# Import libraries
import subprocess
import sys

# Redirect stdout and stderr to the Snakemake log file
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")

# Inputs from Snakemake
dsc_bam = snakemake.input.bam
metrics_file = snakemake.output.metrics

def count_reads(cmd):
    """Run a samtools view command and return the count as int"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(f"Command failed: {cmd}\n{result.stderr}")
        sys.exit(1)
    return int(result.stdout.strip())

# Count total reads
total_reads = count_reads(f"samtools view -c {dsc_bam}")

# Count mapped reads (excluding unmapped)
mapped_reads = count_reads(f"samtools view -F 0x4 -c {dsc_bam}")

# Count mapped reads with MAPQ ≥ 60
mapq60_reads = count_reads(f"samtools view -F 0x4 -q 60 -c {dsc_bam}")

# Compute metrics
aligned_pct = 100 * mapped_reads / total_reads if total_reads else 0
mapq60_pct = 100 * mapq60_reads / mapped_reads if mapped_reads else 0

# Write output
with open(metrics_file, "w") as f:
    f.write(f"Total reads: {total_reads}\n")
    f.write(f"Mapped reads: {mapped_reads}\n")
    f.write(f"Reads with MAPQ ≥ 60: {mapq60_reads}\n")
    f.write(f"Percentage mapped: {aligned_pct:.2f}%\n")
    f.write(f"Percentage with MAPQ ≥ 60 (of mapped): {mapq60_pct:.2f}%\n")