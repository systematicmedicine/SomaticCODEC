"""
--- test_test_ms_add_read_groups.py

Tests the rule test_ms_add_read_groups

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.bam_helpers import count_bam_data_points, count_reads_with_read_group
from definitions.paths.io import ms as MS
from helpers.get_metadata import load_config, get_ms_sample_ids

# Test that read groups have been added
def test_read_groups_added(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get read count pre adding read groups
        input_bam = Path(MS.RAW_BAM.format(ms_sample=ms_sample))
        pre_reads = count_bam_data_points(input_bam)

        # Get number of reads with RG tags after adding read groups     
        output_bam = Path(MS.READ_GROUP_BAM.format(ms_sample=ms_sample))
        post_reads_with_RG = count_reads_with_read_group(output_bam)

        # Assert that all input reads had RG tags added
        assert post_reads_with_RG == pre_reads, (
        f"Reads with RG tag ({post_reads_with_RG}) not equal to input reads ({pre_reads})"
        )

# Test that adding read groups does not change read count
def test_read_counts_preserved(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get read count pre adding read groups
        input_bam = Path(MS.RAW_BAM.format(ms_sample=ms_sample))
        pre_reads = count_bam_data_points(input_bam)

        # Get number of reads with RG tags after adding read groups     
        output_bam = Path(MS.READ_GROUP_BAM.format(ms_sample=ms_sample))
        post_reads = count_bam_data_points(output_bam)

        # Assert that total reads pre adding read groups == total reads post adding read groups
        assert post_reads == pre_reads, (
        f"Post-read group reads ({post_reads}) not equal to pre-read group reads ({pre_reads})"
        )
