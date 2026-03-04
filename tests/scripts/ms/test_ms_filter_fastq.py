"""
--- test_ms_filter_fastq.py

Tests the rule ms_filter_fastq
    - Same number of reads before and after trimming
    - Number of bases less after trimming

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import libraries
from pathlib import Path
from helpers.fastq_helpers import count_fastq_data_points
from definitions.paths.io import ms as MS
from helpers.get_metadata import load_config, get_ms_sample_ids

# Test that filtering decreases the number of reads
def test_filtering_decreases_reads(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        
        # Get read count pre-filtering
        input_fastq1 = Path(MS.TRIMMED_FASTQ_R1.format(ms_sample=ms_sample))
        input_fastq2 = Path(MS.TRIMMED_FASTQ_R2.format(ms_sample=ms_sample))
        input_reads = count_fastq_data_points(input_fastq1) + count_fastq_data_points(input_fastq2)

        # Get read count post-filtering   
        output_fastq1 = Path(MS.FILTERED_FASTQ_R1.format(ms_sample=ms_sample))
        output_fastq2 = Path(MS.FILTERED_FASTQ_R2.format(ms_sample=ms_sample))
        output_reads = count_fastq_data_points(output_fastq1) + count_fastq_data_points(output_fastq2)

        # Assert that read count is reduced by filtering
        assert output_reads < input_reads, f"Read count not reduced for {ms_sample}: {input_reads} -> {output_reads}"
