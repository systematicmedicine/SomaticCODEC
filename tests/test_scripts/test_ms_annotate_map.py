"""
--- test_ms_annotate_map.py

Tests the rule ms_annotate_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from helpers.bam_helpers import count_bam_data_points, count_reads_with_read_group

# Test that read groups have been added
def test_read_groups_added(lightweight_test_run):
    # Get total reads pre adding read groups
    pre_files = glob.glob("tmp/*/*_raw_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Get number of reads with RG tags after ms_annotate_map
    post_files = glob.glob("tmp/*/*_annotated_map.bam")
    post_counts_RG = {Path(f).name: count_reads_with_read_group(f) for f in post_files}
    total_post_reads_with_RG = sum(post_counts_RG.values())

    # Assert that all input reads had RG tags added
    assert total_post_reads_with_RG == total_pre_reads, (
        f"Reads with RG tag ({total_post_reads_with_RG}) not equal to input reads ({total_pre_reads})"
    )

# Test that adding read groups does not change read count
def test_read_counts_preserved(lightweight_test_run):
    # Locate all pre-read group BAM files
    pre_files = glob.glob("tmp/*/*_raw_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-read group BAM files
    post_files = glob.glob("tmp/*/*_annotated_map.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that total reads pre adding read groups == total reads post adding read groups
    assert total_post_reads == total_pre_reads, (
        f"Post-read group reads ({total_post_reads}) not equal to pre-read group reads ({total_pre_reads})"
    )
