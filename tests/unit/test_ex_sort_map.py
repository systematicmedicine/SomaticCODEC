"""
--- test_ex_sort_map.py

Tests the rule ex_sort_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from tests.utils.bam_utils import count_bam_data_points

# Test that sorting does not change read count
def test_read_counts_preserved(lightweight_test_run):
     # Locate all pre-sorting BAM files
    pre_files = glob.glob("tmp/*/*_map_anno.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-sorting BAM files
    post_files = glob.glob("tmp/*/*_map_template_sorted.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre annotation == total reads post annotation
    assert total_post_reads == total_pre_reads, (
        f"Post-sorting reads ({total_post_reads}) not equal to pre-sorting reads ({total_pre_reads})"
    )