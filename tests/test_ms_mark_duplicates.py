"""
--- test_ms_mark_duplicates.py

Tests the rule ms_mark_duplicates

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_utils import count_bam_data_points, count_marked_duplicates

# Test that marking duplicates does not change read count
def test_read_counts_preserved(lightweight_test_run):
    # Locate all pre-markdup BAM files
    pre_files = glob.glob("tmp/*/*_sorted_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-markdup BAM files
    post_files = glob.glob("tmp/*/*_markdup_map.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads pre marking duplicates == total reads post marking duplicates
    assert total_post_reads == total_pre_reads, (
        f"Post-markdup reads ({total_post_reads}) not equal to pre-markdup group reads ({total_pre_reads})"
    )

def test_duplicates_marked(lightweight_test_run):
    # Locate all pre-markdup BAM files
    pre_files = glob.glob("tmp/*/*_sorted_map.bam")
    pre_counts = {Path(f).name: count_marked_duplicates(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-markdup BAM files
    post_files = glob.glob("tmp/*/*_markdup_map.bam")
    post_counts = {Path(f).name: count_marked_duplicates(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert marked duplicate reads post markdup > marked duplicate reads reads pre markdup
    assert total_post_reads > total_pre_reads, (
        f"Marked duplicate reads post markdup ({total_post_reads}) < marked duplicate reads pre-markdup ({total_pre_reads})"
    )