"""
--- test_ex_map.py

Tests the rule ex_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.get_metadata import load_config, get_ex_sample_ids
from helpers.bam_helpers import count_bam_data_points
from helpers.fastq_helpers import count_fastq_data_points

# Test that aligned read count is not greater than input read count
def test_aligned_reads_less_than_input_reads(lightweight_test_run):
    config = load_config("config/config.yaml")
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:
        
        # Get input read count
        fastq_r1 = Path(f"tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz")
        fastq_r2 = Path(f"tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz")
        input_reads = count_fastq_data_points(fastq_r1) + count_fastq_data_points(fastq_r2)

        # Get aligned read count       
        bam_file = Path(f"tmp/{ex_sample}/{ex_sample}_map.bam")
        bam_reads = count_bam_data_points(bam_file)

        # Assert total aligned reads <= total input reads
        assert bam_reads <= input_reads, (
            f"Aligned reads ({bam_reads}) > input reads ({input_reads})"
    )
