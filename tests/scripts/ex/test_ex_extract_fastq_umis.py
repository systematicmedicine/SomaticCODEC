"""
--- test_ex_extract_fastq_umis.py

Tests the rule ex_extract_fastq_umis

Authors:
    - Joshua Johnstone
    - Cameron fraser
"""
import glob
from pathlib import Path
from helpers.fastq_helpers import count_fastq_data_points, sum_len_fastq, first_n_headers
from helpers.get_metadata import load_config
from definitions.paths.io import ex as EX
import pandas as pd
import helpers.get_metadata as md

# Test that extracting UMIs does not change read count
def test_read_counts_preserved(lightweight_test_run):
    
    # Load test config
    config = load_config(lightweight_test_run["test_config_path"])
    ex_lanes = md.get_ex_lane_ids(config)
    
    # Locate all pre-UMI extraction FASTQs
    ex_lanes_df = pd.read_csv(config["metadata"]["ex_lanes_metadata"])
    pre_files = (
        ex_lanes_df["fastq1"].dropna().tolist() +
        ex_lanes_df["fastq2"].dropna().tolist()
    ) 

    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())
    print(total_pre_reads)

    # Locate all post-UMI extraction FASTQs
    post_files = [
        pattern.format(ex_lane=lane)
        for lane in ex_lanes
        for pattern in (EX.UMIXD_FASTQ_R1, EX.UMIXD_FASTQ_R2)
    ]

    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())
    print(total_post_reads)

    # Assert total reads pre UMI extraction == total reads post UMI extraction
    assert total_post_reads == total_pre_reads, (
        f"Post-UMI extraction reads ({total_post_reads}) not equal to pre-UMI extraction reads ({total_pre_reads})"
    )

# Test that reads are reduced by umi length
def test_sequences_are_shorter_by_umi_length(lightweight_test_run):

    # Load test config
    config = load_config(lightweight_test_run["test_config_path"])
    ex_lanes = md.get_ex_lane_ids(config)

    # Locate all pre-UMI extraction FASTQs
    ex_lanes_df = pd.read_csv(config["metadata"]["ex_lanes_metadata"])
    pre_files = (
        ex_lanes_df["fastq1"].dropna().tolist() +
        ex_lanes_df["fastq2"].dropna().tolist()
    ) 

    # Get total length of pre-UMI extraction reads
    pre_length = {Path(f).name: sum_len_fastq(f) for f in pre_files}
    total_pre_length = sum(pre_length.values())

    # Locate all post-UMI extraction FASTQs
    post_files = [
        pattern.format(ex_lane=lane)
        for lane in ex_lanes
        for pattern in (EX.UMIXD_FASTQ_R1, EX.UMIXD_FASTQ_R2)
    ]

    # Get total length of post-UMI extraction reads
    post_length = {Path(f).name: sum_len_fastq(f) for f in post_files}
    total_post_length = sum(post_length.values())

    # Get total number of pre-UMI extraction reads
    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())
    config = load_config(lightweight_test_run["test_config_path"])
    umi_length = config["sci_params"]["ex_extract_fastq_umis"]["umi_length"]

    assert total_post_length == total_pre_length - (umi_length * total_post_reads), (f"Expected {umi_length}bp reduction per read. "
                                                                            f"Actual reduction: {(total_pre_length - total_post_length) / total_post_reads}bp per read")
# Test that reads 
def test_reads_added_to_headers(lightweight_test_run):

    # Load test config
    config = load_config(lightweight_test_run["test_config_path"])
    ex_lanes = md.get_ex_lane_ids(config)

    # Locate pre UMI extraction FASTQ files
    ex_lanes_df = pd.read_csv(config["metadata"]["ex_lanes_metadata"])
    pre_files = (
        ex_lanes_df["fastq1"].dropna().tolist() +
        ex_lanes_df["fastq2"].dropna().tolist()
    ) 
    # Locate post UMI extraction FASTQ files
    post_files = [
        pattern.format(ex_lane=lane)
        for lane in ex_lanes
        for pattern in (EX.UMIXD_FASTQ_R1, EX.UMIXD_FASTQ_R2)
    ]

    # Get first 100 headers of each pre-UMI extraction file
    pre_headers = []
    for f in pre_files:
        pre_headers.extend(first_n_headers(f))   

    # Get first 100 headers of each post-UMI extraction file
    post_headers = []
    for f in post_files:
        post_headers.extend(first_n_headers(f))

    # Assert that each header has a 6bp UMI suffix
    for post_h in post_headers:        
        umi = post_h.split(":")[-1]
        assert len(umi) == 6, f"Expected 6bp UMI suffix, got {len(umi)}bp in header: {post_h}"
        
    