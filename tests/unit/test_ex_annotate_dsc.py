"""
--- test_ex_annotate_dsc.py

Tests the rule ex_annotate_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_utils import count_bam_data_points

# Test that annotation does not change read count
def test_read_counts_preserved(lightweight_test_run):
     # Locate all pre-annotation BAM files
    pre_files = glob.glob("tmp/*/*_map_dsc.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-annotation BAM files
    post_files = glob.glob("tmp/*/*_map_dsc_anno.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre annotation == total reads post annotation
    assert total_post_reads == total_pre_reads, (
        f"Post-annotation reads ({total_post_reads}) not equal to pre-annotation reads ({total_pre_reads})"
    )