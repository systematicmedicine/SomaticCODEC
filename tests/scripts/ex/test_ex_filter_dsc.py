"""
--- test_ex_filter_dsc.py

Tests the rule ex_filter_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
from helpers.bam_helpers import count_bam_data_points, count_bam_reads_under_min_mapq
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

# Test that read count decreases due to filtering
def test_reads_decrease(lightweight_test_run):

    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-filtering BAM files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.ANNOTATED_DSC.format(ex_sample=ex_sample)
        pre_files.append(resolved_path)

    # Locate all post-filtering BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.FILTERED_DSC.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Count reads pre- and post-filtering
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post filtering <= total reads pre filtering
    assert total_post_reads <= total_pre_reads, (
        f"Post-filtering reads ({total_post_reads}) > pre-filtering reads ({total_pre_reads})"
    )

# Test that all reads with MAPQ < min_mapq are removed
def test_mapq_under_min_mapq_removed(lightweight_test_run):

    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all post-filtering BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.FILTERED_DSC.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Load min_mapq from config
    min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"]

    # Count reads with MAPQ < min_mapq
    post_counts = {Path(f).name: count_bam_reads_under_min_mapq(f, min_mapq) for f in post_files}
    total_post_reads = sum(post_counts.values())
    
    # # Assert no reads with MAPQ < min_mapq after filtering
    assert total_post_reads == 0, (
        f"{total_post_reads} reads with MAPQ < min_mapq ({min_mapq}) present after filtering"
    )