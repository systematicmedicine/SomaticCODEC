"""
--- test_ms_trim_fastq.py

Tests the rule ms_trim_fastq
    - Same number of reads before and after trimming
    - Number of bases less after trimming

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import modules
from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_fastqs
from helpers.fastq_helpers import count_fastq_data_points, sum_len_fastq
from definitions.paths.io import ms as MS

# Test that the total number of reads does not change
def test_read_counts_preserved(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_fastq_dict = get_ms_sample_fastqs(config)

    for ms_sample, (input_r1, input_r2) in ms_fastq_dict.items():
        output_r1 = Path(MS.TRIMMED_FASTQ_R1.format(ms_sample=ms_sample))
        output_r2 = Path(MS.TRIMMED_FASTQ_R2.format(ms_sample=ms_sample))

        assert output_r1.exists(), f"Missing output file: {output_r1}"
        assert output_r2.exists(), f"Missing output file: {output_r2}"

        assert count_fastq_data_points(input_r1) == count_fastq_data_points(output_r1), f"R1 read count mismatch for {ms_sample}"
        assert count_fastq_data_points(input_r2) == count_fastq_data_points(output_r2), f"R2 read count mismatch for {ms_sample}"


# Test that total number of bases is reduced by trimming
def test_sequences_are_shorter(lightweight_test_run):

    config = load_config(lightweight_test_run["test_config_path"])
    ms_fastq_dict = get_ms_sample_fastqs(config)

    for ms_sample, (input_r1, input_r2) in ms_fastq_dict.items():
        output_r1 = Path(MS.TRIMMED_FASTQ_R1.format(ms_sample=ms_sample))
        output_r2 = Path(MS.TRIMMED_FASTQ_R2.format(ms_sample=ms_sample))

        assert output_r1.exists(), f"Missing output file: {output_r1}"
        assert output_r2.exists(), f"Missing output file: {output_r2}"

        assert sum_len_fastq(output_r1) < sum_len_fastq(input_r1), f"R1 base count not reduced for {ms_sample}"
        assert sum_len_fastq(output_r2) < sum_len_fastq(input_r2), f"R2 base count not reduced for {ms_sample}"
