"""
--- test_ms_add_mate_information.py

Tests the rule ms_annotate_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.bam_helpers import count_bam_data_points
from definitions.paths.io import ms as MS
from helpers.get_metadata import load_config, get_ms_sample_ids

# Test that adding mate information does not change read count
def test_read_counts_preserved(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get read count pre-mate information
        input_bam = Path(MS.READ_GROUP_BAM.format(ms_sample=ms_sample))
        input_reads = count_bam_data_points(input_bam)

        # Get read count post-mate information      
        output_bam = Path(MS.MATE_INFO_BAM.format(ms_sample=ms_sample))
        output_reads = count_bam_data_points(output_bam)

        # Assert that total reads pre adding mate information == total reads post adding mate information
        assert output_reads == input_reads, (
            f"Post-mate information reads ({output_reads}) > pre-mate information reads ({input_reads})"
    )
