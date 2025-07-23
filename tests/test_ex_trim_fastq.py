"""
--- test_ex_trim_fastq.py

Tests the rule ex_trim_fastq

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# test_ex_trim_fastq.py

import pytest
import glob
from pathlib import Path
from utils.fastq_utils import count_fastq_data_points, sum_len_fastq

def test_read_counts_preserved(lightweight_test_run):
    input_files = sorted(glob.glob("tmp/*/*_r1_demux.fastq.gz"))
    output_files = sorted(glob.glob("tmp/*/*_r1_trim.fastq.gz"))

    # Build a mapping from sample stem to path
    input_map = {Path(f).stem.replace("_r1_demux", ""): f for f in input_files}
    output_map = {Path(f).stem.replace("_r1_trim", ""): f for f in output_files}

    assert input_map.keys() == output_map.keys(), "Mismatch between input and output files"

    for key in input_map:
        in_path = input_map[key]
        out_path = output_map[key]

        in_reads = count_fastq_data_points(in_path)
        out_reads = count_fastq_data_points(out_path)

        assert in_reads == out_reads, f"Read count mismatch for {key}: {in_reads} in vs {out_reads} out"

def test_sequences_are_shorter(lightweight_test_run):
    input_files = sorted(glob.glob("tmp/*/*_r1_demux.fastq.gz"))
    output_files = sorted(glob.glob("tmp/*/*_r1_trim.fastq.gz"))

    input_map = {Path(f).stem.replace("_r1_demux", ""): f for f in input_files}
    output_map = {Path(f).stem.replace("_r1_trim", ""): f for f in output_files}

    assert input_map.keys() == output_map.keys(), "Mismatch between input and output files"

    for key in input_map:
        in_path = input_map[key]
        out_path = output_map[key]

        in_len = sum_len_fastq(in_path)
        out_len = sum_len_fastq(out_path)

        assert out_len < in_len, f"Trimmed seq not shorter for {key}: {in_len} in vs {out_len} out"
