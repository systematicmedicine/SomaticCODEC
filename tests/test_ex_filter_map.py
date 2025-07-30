"""
--- test_ex_filter_map.py

Tests the rule ex_filter_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from scripts.get_metadata import load_config, get_ex_sample_ids
from utils.bam_utils import count_bam_data_points

# Test that filtered read count is not greater than aligned read count
def test_filtered_reads_less_than_aligned_reads(lightweight_test_run):
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:
        
        # Get aligned read count
        pre_file = Path(f"tmp/{ex_sample}/{ex_sample}_map.bam")
        pre_count = count_bam_data_points(pre_file)

        # Get filtered read count       
        post_file = Path(f"tmp/{ex_sample}/{ex_sample}_map_correct.bam")
        post_count = count_bam_data_points(post_file)

        # Assert total reads pre marking duplicates <= total reads post marking duplicates
        assert post_count <= pre_count, (
            f"Post-filtering reads ({post_count}) > pre-filtering reads ({pre_count}) for {ex_sample}"
            )