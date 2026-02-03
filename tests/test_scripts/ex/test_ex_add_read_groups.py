"""
--- test_ex_add_read_groups.py

Tests the rule ex_add_read_groups

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from helpers.bam_helpers import count_bam_data_points

# Test that the read counts don't change during annotation
def test_reads_decrease(lightweight_test_run):
    # Locate all pre-annotation BAM files
    pre_files = glob.glob("tmp/*/*_map_correct.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-annotation BAM files
    post_files = glob.glob("tmp/*/*_map_read_group.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post annotation == total reads pre annotation
    assert total_post_reads == total_pre_reads, (
        f"Post-annotation reads ({total_post_reads}) != pre-annotation reads ({total_pre_reads})"
    )


