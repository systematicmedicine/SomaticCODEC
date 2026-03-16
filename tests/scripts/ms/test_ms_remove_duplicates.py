"""
--- test_ms_remove_duplicates.py

Tests the rule ms_remove_duplicates

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.bam_helpers import count_bam_data_points
from helpers.get_metadata import load_config, get_ms_sample_ids
import definitions.paths.io.ms as MS

# Test that removing duplicates decreases read count
def test_read_counts_decrease(lightweight_test_run):
    
    # Load ms_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    
    # Locate all pre-dedup BAM files
    pre_files = []
    for ms_sample in ms_samples:
        resolved_path = MS.MATE_INFO_BAM.format(ms_sample=ms_sample)
        pre_files.append(resolved_path)

    # Locate all post-dedup BAM files
    post_files = []
    for ms_sample in ms_samples:
        resolved_path = MS.DEDUPED_BAM.format(ms_sample=ms_sample)
        pre_files.append(resolved_path)
    
    # Count pre and post reads
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that total reads post dedup < total reads pre dedup
    assert total_post_reads < total_pre_reads, (
        f"Removing duplicates did not decrease read count. {total_pre_reads} pre dedup -> {total_post_reads} post dedup"
    )