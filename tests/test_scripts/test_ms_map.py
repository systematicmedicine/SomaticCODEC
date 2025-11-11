"""
--- test_ms_map.py

Tests the rule ms_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.bam_helpers import count_bam_data_points
from helpers.fastq_helpers import count_fastq_data_points

# Test that aligned read count is not greater than input read count
def test_aligned_reads_less_than_input_reads(lightweight_test_run):
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get input read count
        fastq_r1 = Path(f"tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz")
        fastq_r2 = Path(f"tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz")
        input_reads = count_fastq_data_points(fastq_r1) + count_fastq_data_points(fastq_r2)

        # Get aligned read count       
        bam_file = Path(f"tmp/{ms_sample}/{ms_sample}_raw_map.bam")
        bam_reads = count_bam_data_points(bam_file)

        # Assert total aligned reads <= total input reads
        assert bam_reads <= input_reads, (
            f"Aligned reads ({bam_reads}) > input reads ({input_reads})"
    )