"""
--- test_ex_sort_dsc.py

Tests the rule ex_sort_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_stats import count_bam_data_points

def test_read_counts_preserved(lightweight_test_run):
     # Locate all pre-sorting BAM files
    pre_files = glob.glob("tmp/*/*_map_dsc_unsorted.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-sorting BAM files
    post_files = glob.glob("tmp/*/*_map_dsc.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre sorting == total reads post sorting
    assert total_post_reads == total_pre_reads, (
        f"Post-sorting reads ({total_post_reads}) not equal to pre-sorting reads ({total_pre_reads})"
    )