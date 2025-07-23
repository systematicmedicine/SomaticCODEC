"""
--- test_ex_remap_dsc.py

Tests the rule ex_remap_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_utils import count_bam_data_points

def test_read_counts_preserved(lightweight_test_run):
     # Locate all pre-remapping BAM files
    pre_files = glob.glob("tmp/*/*_unmap_dsc.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-remapping BAM files
    post_files = glob.glob("tmp/*/*_map_dsc_unsorted.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre remapping == total reads post remapping
    assert total_post_reads == total_pre_reads, (
        f"Post-remapping reads ({total_post_reads}) not equal to pre-remapping reads ({total_pre_reads})"
    )