#!/usr/bin/env python3
"""
--- ex_total_read_loss.py ---

Calculates the number of reads lost between the start and end of the ex pipeline

Rule to be used exclusively with parent rule, ex_total_read_loss

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
import json
import subprocess
import pysam
import sys
import argparse

def main(args):
    # Initiate logging
    sys.stdout = open(args.log, "a")
    sys.stderr = open(args.log, "a")
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
        
    # Define sample name
    sample = args.sample

    # Count R1 and R2 reads using seqkit
    r1_count = count_fastq_reads(args.input_fastq1)
    r2_count = count_fastq_reads(args.input_fastq2)
    paired_reads_post_demux = min(r1_count, r2_count)

    # Count reads in final DSC BAM
    final_dsc_reads = count_bam_reads(args.dsc_final)

    # Calculate read loss
    reads_lost = paired_reads_post_demux - final_dsc_reads
    percent_lost = (reads_lost / paired_reads_post_demux * 100) if paired_reads_post_demux > 0 else 0.0

    # Write results
    result = {
        "sample": sample,
        "paired_reads_post_demux": paired_reads_post_demux,
        "final_dsc_reads": final_dsc_reads,
        "percent_reads_lost": round(percent_lost, 2)
    }

    with open(args.metrics, 'w') as out_f:
        json.dump(result, out_f, indent=4)

    print("[INFO] Completed ex_total_read_loss.py")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_fastq1", required=True)
    parser.add_argument("--input_fastq2", required=True)
    parser.add_argument("--dsc_final", required=True)
    parser.add_argument("--metrics", required=True)
    parser.add_argument("--sample", required=True)
    parser.add_argument("--log", required=True)
    args = parser.parse_args()
    main(args=args)
