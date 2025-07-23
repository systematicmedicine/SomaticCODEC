"""
--- test_ex_filter_map.py

Tests the rule ex_filter_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
from utils.bam_utils import count_bam_data_points

# Test that filtered read count is not greater than aligned read count
def test_filtered_reads_less_than_aligned_reads(lightweight_test_run):
    ex_samples = pd.read_csv("tests/configs/lightweight_test_run/ex_samples.csv")["ex_sample"].to_list()

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