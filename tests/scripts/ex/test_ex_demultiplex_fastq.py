"""
--- test_ex_demultiplex_fastq.py

Tests the rule ex_demultiplex_fastq

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

from pathlib import Path
import glob
from helpers.fastq_helpers import count_fastq_data_points

def test_read_counts(lightweight_test_run):
    # Locate all pre-demux FASTQ files
    pre_files = glob.glob("tmp/*/*_r1_umi_extracted.fastq.gz")
    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-demux FASTQ files
    post_files = glob.glob("tmp/*/*_r1_demux.fastq.gz")
    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre demux >= total reads post demux
    assert total_post_reads <= total_pre_reads, (
        f"Post-demux reads ({total_post_reads}) > pre-demux reads ({total_pre_reads})"
    )

    # Assertion 2: At least 20% of reads retained after demux
    assert total_post_reads >= 0.2 * total_pre_reads, (
        f"Post-demux reads ({total_post_reads}) < 20% of pre-demux reads ({total_pre_reads})"
    )