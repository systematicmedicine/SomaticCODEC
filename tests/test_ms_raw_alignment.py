"""
--- test_ms_raw_alignment.py

Tests the rule ms_raw_alignment

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
from utils.bam_utils import count_bam_data_points
from utils.fastq_utils import count_fastq_data_points

# Test that aligned read count is not greater than input read count
def test_aligned_reads_less_than_input_reads():
    ms_samples_csv = pd.read_csv("tests/configs/lightweight_test_run/ms_samples.csv")

    for ms_sample in ms_samples_csv["ms_sample"].to_list():
        
        # Get input read count
        row = ms_samples_csv[ms_samples_csv["ms_sample"] == ms_sample].iloc[0]
        fastq_r1 = row["fastq1"]
        fastq_r2 = row["fastq2"]
        input_reads = count_fastq_data_points(fastq_r1) + count_fastq_data_points(fastq_r2)

        # Get aligned read count       
        bam_file = Path(f"tmp/{ms_sample}/{ms_sample}_raw_map.bam")
        bam_reads = count_bam_data_points(bam_file)

        # Assert total aligned reads <= total input reads
        assert bam_reads <= input_reads, (
            f"Aligned reads ({bam_reads}) > input reads ({input_reads})"
    )