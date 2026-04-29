"""
--- test_ex_trim_fastq.py

Tests the rule ex_filter_fastq

Authors:
    - Cameron Fraser
    - Joshua Johnstone
"""

from pathlib import Path
from helpers.fastq_helpers import count_fastq_data_points
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

# Test that filtering decreases the number of reads
def test_filtering_decreases_reads(lightweight_test_run):

    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-filtering FASTQ files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.TRIMMED_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.TRIMMED_FASTQ_R2.format(ex_sample=ex_sample)
        pre_files.append(resolved_path_r1)
        pre_files.append(resolved_path_r2)

    # Locate all post-filtering FASTQ files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path_r1 = EX.FILTERED_FASTQ_R1.format(ex_sample=ex_sample)
        resolved_path_r2 = EX.FILTERED_FASTQ_R2.format(ex_sample=ex_sample)
        pre_files.append(resolved_path_r1)
        pre_files.append(resolved_path_r2)

    # Count reads pre- and post-filtering
    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert that filtering reduced read count
    assert total_post_reads < total_pre_reads, (
        f"Filtering did not reduce the total number of reads: "
        f"{total_pre_reads} in vs {total_post_reads} out"
    )