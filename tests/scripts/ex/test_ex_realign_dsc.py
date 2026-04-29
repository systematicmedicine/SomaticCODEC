"""
--- test_ex_realign_dsc.py

Tests the rule ex_realign_dsc

Authors:
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.bam_helpers import count_bam_data_points
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

# Test that remapping does not change read count
def test_read_counts_preserved(lightweight_test_run):

    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-remapping BAM files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.RAW_DSC.format(ex_sample=ex_sample)
        pre_files.append(resolved_path)

    # Locate all post-remapping BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.REALIGNED_DSC.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Count reads pre- and post-remapping
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that total reads pre remapping == total reads post remapping
    assert total_post_reads == total_pre_reads, (
        f"Post-remapping reads ({total_post_reads}) not equal to pre-remapping reads ({total_pre_reads})"
    )