"""
--- test_ms_extract_fastq_umis.py

Tests the rule ms_extract_fastq_umis

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import glob
from pathlib import Path
from utils.fastq_utils import count_fastq_data_points, sum_len_fastq, first_n_headers
from scripts.get_metadata import load_config

# Test that extracting UMIs does not change read count
def test_read_counts_preserved(lightweight_test_run):
    # Locate all pre-UMI extraction FASTQs
    pre_files = glob.glob("tmp/downloads/S004*.fastq.gz") + glob.glob("tmp/downloads/S005*.fastq.gz")
    pre_counts = {Path(f).name: count_fastq_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())
    print(total_pre_reads)

    # Locate all post-UMI extraction FASTQs
    post_files = glob.glob("tmp/S004/*_umi_extracted*.fastq.gz") + glob.glob("tmp/S005/*_umi_extracted*.fastq.gz")
    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())
    print(total_post_reads)

    # Assert total reads pre UMI extraction == total reads post UMI extraction
    assert total_post_reads == total_pre_reads, (
        f"Post-UMI extraction reads ({total_post_reads}) not equal to pre-UMI extraction reads ({total_pre_reads})"
    )

# Test that each r1 read sequence is reduced by the length of the spacer + umi
def test_sequences_are_shorter_by_spacer_plus_umi(lightweight_test_run):
    # Locate all pre-UMI extraction r1 FASTQs
    pre_files = glob.glob("tmp/downloads/S004*r1.fastq.gz") + glob.glob("tmp/downloads/S005*r1.fastq.gz")

    # Get total length of pre-UMI extraction reads
    pre_length = {Path(f).name: sum_len_fastq(f) for f in pre_files}
    total_pre_length = sum(pre_length.values())

    # Locate all post-UMI extraction FASTQs
    post_files = glob.glob("tmp/S004/*_umi_extracted*r1.fastq.gz") + glob.glob("tmp/S005/*_umi_extracted*r1.fastq.gz")

    # Get total length of post-UMI extraction reads
    post_length = {Path(f).name: sum_len_fastq(f) for f in post_files}
    total_post_length = sum(post_length.values())

    # Get total number of pre-UMI extraction reads
    post_counts = {Path(f).name: count_fastq_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Get lengths from config
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    spacer_length = config["ms_extract_fastq_umis"]["spacer_length"]
    umi_length = config["ms_extract_fastq_umis"]["umi_length"]
    spacer_umi = spacer_length + umi_length

    assert total_post_length == total_pre_length - (spacer_umi * total_post_reads), (f"Expected {spacer_umi}bp reduction per read. "
                                                                            f"Actual reduction: {(total_pre_length - total_post_length) / total_post_reads}bp per read")
# Test that reads 
def test_reads_added_to_headers(lightweight_test_run):
    # Locate pre- and post-UMI extraction FASTQ files
    pre_files = glob.glob("tmp/downloads/S004*.fastq.gz") + glob.glob("tmp/downloads/S005*.fastq.gz")
    post_files = glob.glob("tmp/S004/*_umi_extracted*.fastq.gz") + glob.glob("tmp/S005/*_umi_extracted*.fastq.gz")

    # Get first 100 headers of each pre-UMI extraction file
    pre_headers = []
    for f in pre_files:
        pre_headers.extend(first_n_headers(f))   

    # Get first 100 headers of each post-UMI extraction file
    post_headers = []
    for f in post_files:
        post_headers.extend(first_n_headers(f))

    # Assert that each header has a 12bp UMI suffix
    for post_h in post_headers:        
        umi = post_h.split(":")[-1]
        assert len(umi) == 12, f"Expected 12bp UMI suffix, got {len(umi)}bp in header: {post_h}"
        
    