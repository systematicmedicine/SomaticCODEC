"""
--- test_ex_filter_dsc.py

Tests the rule ex_filter_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from utils.bam_utils import count_bam_data_points, count_bam_reads_under_min_mapq
from scripts.get_metadata import load_config

# Test that read count decreases due to filtering
def test_reads_decrease(lightweight_test_run):
    # Locate all pre-filtering BAM files
    pre_files = glob.glob("tmp/*/*_map_dsc_anno.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-filtering BAM files
    post_files = glob.glob("tmp/*/*_map_dsc_anno_filtered.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post filtering <= total reads pre filtering
    assert total_post_reads <= total_pre_reads, (
        f"Post-filtering reads ({total_post_reads}) > pre-filtering reads ({total_pre_reads})"
    )

# Test that all reads with MAPQ < min_mapq are removed
def test_mapq_under_min_mapq_removed(lightweight_test_run):
    # Locate all post-filtering BAM files
    post_files = glob.glob("tmp/*/*_map_dsc_anno_filtered.bam")
    post_counts = {Path(f).name: count_bam_reads_under_min_mapq(f) for f in post_files}
    total_post_reads = sum(post_counts.values())
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    min_mapq = config["ex_filter_dsc"]["min_mapq"]

    # # Assert no reads with MAPQ < min_mapq after filtering
    assert total_post_reads == 0, (
        f"{total_post_reads} reads with MAPQ < min_mapq ({min_mapq}) present after filtering"
    )