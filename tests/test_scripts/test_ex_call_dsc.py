"""
--- test_ex_call_dsc.py

Tests the rule ex_call_dsc

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""
from pathlib import Path
import glob
import sys
from collections import Counter
import pysam

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from helpers.bam_helpers import count_bam_data_points

# Test that the read count decreases due to collapsing reads
def test_reads_decrease(lightweight_test_run):
     # Locate all pre-call BAM files
    pre_files = glob.glob("tmp/*/*_map_anno.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-call BAM files
    post_files = glob.glob("tmp/*/*_unmap_dsc.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post calling <= total reads pre calling
    assert total_post_reads <= total_pre_reads, (
        f"Post-calling reads ({total_post_reads}) > pre-calling reads ({total_pre_reads})"
    )

def test_no_duplicated_read_names(lightweight_test_run):    
    # Locate all post-UMI grouping BAM files
    post_files = glob.glob("tmp/*/*_unmap_dsc.bam")

    # Collect relevant data about post-CODEC consensus calling BAMs
    for bam_path in post_files:

        read_names = []

        with pysam.AlignmentFile(bam_path, "rb") as bam:
            for read in bam:
                # Add read name to list
                read_names.append(read.query_name)

            # Assert read query names appear twice only (once each for R1 and R2)
            name_counts = Counter(read_names)
            for name, count in name_counts.items():
                assert count == 2, f"Query name {name} appears {count} times in {bam_path}, expected 2 appearances"