"""
--- test_ex_call_dsc.py

Tests the rule ex_call_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_stats import count_bam_data_points, count_bam_q2_bases

def test_reads_decrease(lightweight_test_run):
     # Locate all pre-call BAM files
    pre_files = glob.glob("tmp/*/*_map_template_sorted.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-call BAM files
    post_files = glob.glob("tmp/*/*_unmap_dsc.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post annotation <= total reads pre annotation
    assert total_post_reads <= total_pre_reads, (
        f"Post-sorting reads ({total_post_reads}) > pre-sorting reads ({total_pre_reads})"
    )

def test_q2_bases_increase(lightweight_test_run):
     # Locate all pre-call BAM files
    pre_files = glob.glob("tmp/*/*_map_template_sorted.bam")
    pre_counts = {Path(f).name: count_bam_q2_bases(f) for f in pre_files}
    total_pre_Q2_bases = sum(pre_counts.values())

    # Locate all post-call BAM files
    post_files = glob.glob("tmp/*/*_unmap_dsc.bam")
    post_counts = {Path(f).name: count_bam_q2_bases(f) for f in post_files}
    total_post_Q2_bases = sum(post_counts.values())

    # Assert total Q2 bases post calling dsc >= total Q2 bases pre calling dsc
    assert total_post_Q2_bases >= total_pre_Q2_bases, (
        f"Q2 bases post calling dsc ({total_post_Q2_bases}) > Q2 bases pre calling dsc ({total_pre_Q2_bases})"
    )