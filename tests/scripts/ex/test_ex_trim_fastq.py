"""
--- test_ex_trim_fastq.py

Tests the rule ex_trim_fastq

Authors:
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""

from pathlib import Path
import os
from helpers.fastq_helpers import count_fastq_data_points, sum_len_fastq
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

def test_read_counts_preserved(lightweight_test_run):
    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-trimming FASTQ files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.DEMUXD_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.DEMUXD_FASTQ_R2.format(ex_sample=ex_sample)
        pre_files.append(resolved_path_r1)
        pre_files.append(resolved_path_r2)

    # Locate all post-trimming FASTQ files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.TRIMMED_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.TRIMMED_FASTQ_R2.format(ex_sample=ex_sample)
        post_files.append(resolved_path_r1)
        post_files.append(resolved_path_r2)

    # Count reads pre- and post-trimming
    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that total reads pre- and post-trimming match
    assert total_pre_reads == total_post_reads, f"Read count mismatch after trimming: {total_pre_reads} in vs {total_post_reads} out"

def test_sequences_are_shorter(lightweight_test_run):
    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-trimming FASTQ files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.DEMUXD_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.DEMUXD_FASTQ_R2.format(ex_sample=ex_sample)
        pre_files.append(resolved_path_r1)
        pre_files.append(resolved_path_r2)

    # Locate all post-trimming FASTQ files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.TRIMMED_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.TRIMMED_FASTQ_R2.format(ex_sample=ex_sample)
        post_files.append(resolved_path_r1)
        post_files.append(resolved_path_r2)

    # Get read lengths pre- and post-trimming
    pre_lengths = {Path(f).name: sum_len_fastq(f) for f in pre_files}
    total_pre_lengths = sum(pre_lengths.values())

    post_lengths = {Path(f).name: sum_len_fastq(f) for f in post_files}
    total_post_lengths = sum(post_lengths.values())

    # Assert that lengths are shorter post-trimming
    assert total_post_lengths < total_pre_lengths, f"Trimmed seq not shorter: {total_pre_lengths} in vs {total_post_lengths} out"
