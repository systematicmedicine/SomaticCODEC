"""
--- test_ms_sort_bam.py

Tests the rule ms_sort_bam

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_utils import count_bam_data_points

# Test that sorting does not change read count
def test_read_counts_preserved(lightweight_test_run):
    # Locate all pre-sorting BAM files
    pre_files = glob.glob("tmp/*/*_read_group_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-sorting BAM files
    post_files = glob.glob("tmp/*/*_sorted_map.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre sorting == total reads post sorting
    assert total_post_reads == total_pre_reads, (
        f"Post-sorting reads ({total_post_reads}) not equal to pre-sorting reads ({total_pre_reads})"
    )