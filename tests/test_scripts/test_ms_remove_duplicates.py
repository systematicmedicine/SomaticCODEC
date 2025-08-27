"""
--- test_ms_remove_duplicates.py

Tests the rule ms_remove_duplicates

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

# Test that removing duplicates decreases read count
def test_read_counts_decrease(lightweight_test_run):
    # Locate all pre-dedup BAM files
    pre_files = glob.glob("tmp/*/*_read_group_map.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-dedup BAM files
    post_files = glob.glob("tmp/*/*_deduped_map.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads post dedup < total reads pre dedup
    assert total_post_reads < total_pre_reads, (
        f"Removing duplicates did not decrease read count. {total_pre_reads} pre dedup -> {total_post_reads} post dedup"
    )