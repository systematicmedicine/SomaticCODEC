"""
--- ex_total_read_loss.py ---

Calculates the number of reads lost between the start and end of the ex pipeline

Rule to be used exclusively with parent rule, ex_total_read_loss

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import json
import subprocess
import pysam
import os

# Initiate logging
sys.stdout = open(snakemake.log[0], "a")
sys.stderr = open(snakemake.log[0], "a")
print("[INFO] Starting ex_total_read_loss.py")

# Count number of reads in a FASTQ file
def count_fastq_reads(fastq_path):
    try:
        result = subprocess.run(
            ["seqkit", "stats", "-T", fastq_path],
            check=True,
            capture_output=True,
            text=True
        )
        lines = result.stdout.strip().splitlines()
        if len(lines) < 2:
            raise ValueError(f"Unexpected output from seqkit:\n{result.stdout}")
        return int(lines[1].split('\t')[3]) 
    except Exception as e:
        raise RuntimeError(f"Failed to count reads in {fastq_path} using seqkit:\n{e}")

# Count number of reads in a BAM file
def count_bam_reads(bam_path):

    with pysam.AlignmentFile(bam_path, "rb") as bam:
        return sum(1 for _ in bam)

# Main logic
def main(snakemake):
    # Count R1 and R2 reads using seqkit
    r1_count = count_fastq_reads(snakemake.input.input_fastq1)
    r2_count = count_fastq_reads(snakemake.input.input_fastq2)
    paired_reads = min(r1_count, r2_count)

    # Count reads in all final DSC BAMs
    final_dsc_reads = 0
    for bam in snakemake.input.dsc_final:
        final_dsc_reads += count_bam_reads(bam)

    # Calculate read loss
    reads_lost = paired_reads - final_dsc_reads
    percent_lost = (reads_lost / paired_reads * 100) if paired_reads > 0 else 0.0

    # Determine lane name from output path
    lane_name = os.path.basename(snakemake.output.file_path).split("_")[0]

    # Write results
    result = {
        "lane": lane_name,
        "paired_input_reads": paired_reads,
        "final_dsc_reads": final_dsc_reads,
        "percent_reads_lost": round(percent_lost, 2)
    }

    with open(snakemake.output.file_path, 'w') as out_f:
        json.dump(result, out_f, indent=4)

    print("[INFO] Completed ex_total_read_loss.py")

if __name__ == "__main__":
    main(snakemake)
