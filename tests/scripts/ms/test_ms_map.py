"""
--- test_ms_map.py

Tests the rule ms_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""

from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.bam_helpers import count_bam_data_points
from helpers.fastq_helpers import count_fastq_data_points
from definitions.paths.io import ms as MS

# Test that aligned read count is not greater than input read count
def test_aligned_reads_less_than_input_reads(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get input read count
        fastq_r1 = Path(MS.FILTERED_FASTQ_R1.format(ms_sample=ms_sample))
        fastq_r2 = Path(MS.FILTERED_FASTQ_R2.format(ms_sample=ms_sample))
        input_reads = count_fastq_data_points(fastq_r1) + count_fastq_data_points(fastq_r2)

        # Get aligned read count       
        bam_file = Path(MS.RAW_BAM.format(ms_sample=ms_sample))
        bam_reads = count_bam_data_points(bam_file)

        # Assert total aligned reads <= total input reads
        assert bam_reads <= input_reads, (
            f"Aligned reads ({bam_reads}) > input reads ({input_reads})"
    )