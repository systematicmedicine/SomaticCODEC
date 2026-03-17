"""
--- test_ex_add_read_groups.py

Tests the rule ex_add_read_groups

Authors:
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.bam_helpers import count_bam_data_points
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

# Test that the read counts don't change during adding read groups
def test_reads_decrease(lightweight_test_run):
    
    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-read group BAM files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.FILTERED_BAM.format(ex_sample=ex_sample)
        pre_files.append(resolved_path)

    # Locate all post-read group BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.READ_GROUP_BAM.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Count reads pre- and post- adding read groups
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post read group == total reads pre read group
    assert total_post_reads == total_pre_reads, (
        f"Post-read group reads ({total_post_reads}) != pre-read group reads ({total_pre_reads})"
    )


