"""
--- test_ex_call_dsc.py

Tests the rule ex_call_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""
from pathlib import Path
import glob
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from helpers.bam_helpers import count_bam_data_points, count_bam_ss_qual_bases

# Test that the read count decreases due to collapsing reads
def test_reads_decrease(lightweight_test_run):
     # Locate all pre-call BAM files
    pre_files = glob.glob("tmp/*/*_map_anno.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-call BAM files
    post_files = glob.glob("tmp/*/*_unmap_dsc.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post calling <= total reads pre calling
    assert total_post_reads <= total_pre_reads, (
        f"Post-calling reads ({total_post_reads}) > pre-calling reads ({total_pre_reads})"
    )