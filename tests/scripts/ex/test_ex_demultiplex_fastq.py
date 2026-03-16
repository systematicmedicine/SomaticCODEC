"""
--- test_ex_demultiplex_fastq.py

Tests the rule ex_demultiplex_fastq

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

from pathlib import Path
from helpers.fastq_helpers import count_fastq_data_points
from helpers.get_metadata import load_config, get_ex_sample_ids, get_ex_lane_ids
import definitions.paths.io.ex as EX

def test_read_counts(lightweight_test_run):

    # Load ex_sample and ex_lane IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)
    ex_lanes = get_ex_lane_ids(config)

    # Locate all pre-demux FASTQ files
    pre_files = []
    for ex_lane in ex_lanes:
        resolved_path_r1 = EX.UMIXD_FASTQ_R1.format(ex_lane=ex_lane)
        resolved_path_r2 = EX.UMIXD_FASTQ_R2.format(ex_lane=ex_lane)
        pre_files.append(resolved_path_r1)
        pre_files.append(resolved_path_r2)

    # Locate all post-demux FASTQ files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.DEMUXD_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.DEMUXD_FASTQ_R2.format(ex_sample=ex_sample)
        post_files.append(resolved_path_r1)
        post_files.append(resolved_path_r2)

    # Count reads pre- and post-demux
    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads pre demux >= total reads post demux
    assert total_post_reads <= total_pre_reads, (
        f"Post-demux reads ({total_post_reads}) > pre-demux reads ({total_pre_reads})"
    )

    # Assertion 2: At least 20% of reads retained after demux
    assert total_post_reads >= 0.2 * total_pre_reads, (
        f"Post-demux reads ({total_post_reads}) < 20% of pre-demux reads ({total_pre_reads})"
    )