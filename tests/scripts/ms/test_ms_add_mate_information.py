"""
--- test_ms_add_mate_information.py

Tests the rule ms_annotate_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from helpers.bam_helpers import count_bam_data_points

# Test that adding mate information does not change read count
def test_read_counts_preserved(lightweight_test_run):
    # Locate all pre-mate information BAM files
    pre_files = glob.glob("tmp/*/*_read_group_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-mate information group BAM files
    post_files = glob.glob("tmp/*/*_annotated_map.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that total reads pre adding mate information == total reads post adding mate information
    assert total_post_reads == total_pre_reads, (
        f"Post-mate information reads ({total_post_reads}) not equal to pre-mate information reads ({total_pre_reads})"
    )
