"""
--- test_ex_call_dsc.py

Tests the rule ex_call_dsc

Authors:
    - Joshua Johnstone
    - Cameron Fraser
"""
from pathlib import Path
from collections import Counter
import pysam
from helpers.bam_helpers import count_bam_data_points
from helpers.get_metadata import load_config, get_ex_sample_ids
import definitions.paths.io.ex as EX

# Test that the read count decreases due to collapsing reads
def test_reads_decrease(lightweight_test_run):

    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all pre-call BAM files
    pre_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.UMI_GROUPED_BAM.format(ex_sample=ex_sample)
        pre_files.append(resolved_path)

    # Locate all post-call BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.RAW_DSC.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Counts reads pre- and post-call
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post calling <= total reads pre calling
    assert total_post_reads <= total_pre_reads, (
        f"Post-calling reads ({total_post_reads}) > pre-calling reads ({total_pre_reads})"
    )

def test_no_duplicated_read_names(lightweight_test_run):    
    
    # Load ex_sample IDs
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    # Locate all post-call BAM files
    post_files = []
    for ex_sample in ex_samples:
        resolved_path = EX.RAW_DSC.format(ex_sample=ex_sample)
        post_files.append(resolved_path)

    # Collect relevant data about post-CODEC consensus calling BAMs
    for bam_path in post_files:

        read_names = []

        with pysam.AlignmentFile(bam_path, "rb", check_sq=False) as bam:
            for read in bam:
                # Add read name to list
                read_names.append(read.query_name)

            # Assert read query names appear once only (R1 and R2 collapsed into consensus read)
            name_counts = Counter(read_names)
            for name, count in name_counts.items():
                assert count == 1, f"Query name {name} appears {count} times in {bam_path}, expected 1 appearance"