"""
--- test_ex_group_by_umi.py

Tests the rule ex_group_by_umi

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
import pysam
from collections import Counter
from scripts.helpers.bam_helpers import count_bam_data_points

def test_group_by_umi(lightweight_test_run):
    # Locate all pre-UMI grouping BAM files
    pre_files = glob.glob("tmp/*/*_map_anno.bam")
    
    # Locate all post-UMI grouping BAM files
    post_files = glob.glob("tmp/*/*_map_umi_grouped.bam")

    # Get number of reads in pre- and post-UMI grouping files
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assertion 1: Total reads post-UMI grouping <= total reads pre-UMI grouping
    assert total_post_reads <= total_pre_reads, (
        f"Post-UMI grouping reads ({total_post_reads}) > pre-UMI grouping reads ({total_pre_reads})"
    )

    # Collect relevant data about post-UMI grouping BAMs
    for bam_path in post_files:

        read_names = []
        all_reads_have_UMI_in_RX = True
        no_reads_have_BX = True
        all_reads_have_MI = True

        with pysam.AlignmentFile(bam_path, "rb") as bam:
            for read in bam:

                # Add read name to list
                read_names.append(read.query_name)

                # Check for 6bp UMI in RX tag
                if not read.has_tag("RX") or len(read.get_tag("RX")) != 6:
                    all_reads_have_UMI_in_RX = False

                # Check for BX tag
                if read.has_tag("BX"):
                    no_reads_have_BX = False

                # Check for MI tag
                if not read.has_tag("MI"):
                    all_reads_have_MI = False
        
            # Assertion 2: All reads have 6bp UMIs in the RX:Z tag
            assert all_reads_have_UMI_in_RX == True, (f"BAM file {bam_path} has reads missing 6bp UMIs in RX tag")
            
            # Assertion 3: All reads have UMI groups in the MI:Z tag
            assert all_reads_have_MI == True, (f"BAM file {bam_path} has reads missing MI tags")

            # Assertion 4: Read query names appear twice only (once each for R1 and R2)
            name_counts = Counter(read_names)
            for name, count in name_counts.items():
                assert count == 2, f"Query name {name} appears {count} times in {bam_path}, expected 2 appearances"
