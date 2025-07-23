"""
--- test_ms_filter_fastq.py

Tests the rule ms_filter_fastq
    - Same number of reads before and after trimming
    - Number of bases less after trimming

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Import libraries
import pytest
import glob
from pathlib import Path
from utils.fastq_utils import count_fastq_data_points

# Test that filtering decreases the number of reads
def test_filtering_decreases_reads(lightweight_test_run):

    input_files = glob.glob("tmp/*/*_trim_r1.fastq.gz")
    output_files = glob.glob("tmp/*/*_filter_r1.fastq.gz")

    # Build maps from sample name to file path
    input_map = {Path(f).stem.replace("_trim_r1", ""): f for f in input_files}
    output_map = {Path(f).stem.replace("_filter_r1", ""): f for f in output_files}

    assert input_map.keys() == output_map.keys(), "Mismatch between input and output files"

    for sample_id in input_map:
        in_path = Path(input_map[sample_id])
        out_path = Path(output_map[sample_id])

        assert in_path.exists(), f"Missing input file: {in_path}"
        assert out_path.exists(), f"Missing output file: {out_path}"

        in_reads = count_fastq_data_points(in_path)
        out_reads = count_fastq_data_points(out_path)

        assert out_reads < in_reads, f"Read count not reduced for {sample_id}: {in_reads} -> {out_reads}"
