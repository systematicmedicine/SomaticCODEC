"""
--- test_ex_annotate_map.py

Tests the rule ex_annotate_map

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import glob
import sys
import pysam
import pytest
from snakemake import snakemake
import shutil
import yaml
from collections import Counter

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from helpers.bam_helpers import count_bam_data_points

# Test that the read count decreases due to collapsing by UMI
def test_reads_decrease(lightweight_test_run):
    # Locate all pre-annotation BAM files
    pre_files = glob.glob("tmp/*/*_map_correct.bam")
    pre_counts = {Path(f).name: count_bam_data_points(f) for f in pre_files}
    total_pre_reads = sum(pre_counts.values())

    # Locate all post-annotation BAM files
    post_files = glob.glob("tmp/*/*_map_anno.bam")
    post_counts = {Path(f).name: count_bam_data_points(f) for f in post_files}
    total_post_reads = sum(post_counts.values())

    # Assert total reads post annotation <= total reads pre annotation
    assert total_post_reads <= total_pre_reads, (
        f"Post-annotation reads ({total_post_reads}) > pre-annotation reads ({total_pre_reads})"
    )

def test_MI_bam_tag_added():
    # Locate all post-annotation BAM files
    post_files = glob.glob("tmp/*/*_map_anno.bam")

    for bam_path in post_files:
        all_reads_have_MI = True
        with pysam.AlignmentFile(bam_path, "rb") as bam:
            for read in bam:
                if not read.has_tag("MI"):
                    print(f"Read {read.query_name} is missing MI")
                    all_reads_have_MI = False
        
        assert all_reads_have_MI == True, (f"BAM file {bam} has reads without MI tags")

@pytest.mark.parametrize("map_correct_path", [
    ("tests/data/test_ex_annotate_map/map_correct_unmapped_reads.bam"),
    ("tests/data/test_ex_annotate_map/map_correct_secondary_supplemental_reads.bam"),
    ("tests/data/test_ex_annotate_map/map_correct_primary_mapped.bam")
     ])
def test_group_by_umi(tmp_path, map_correct_path):
    # Define params and paths
    ex_sample = "EX001"
    map_correct_renamed = f"tmp/{ex_sample}/{ex_sample}_map_correct.bam"
    grouped_bam_path = f"tmp/{ex_sample}/{ex_sample}_map_anno.bam"

    # Make expected input directory
    input_dir = Path(f"tmp/{ex_sample}")
    input_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy test bam to expected input directory
    shutil.copy(map_correct_path, map_correct_renamed)

    # Load config
    with open("config/config.yaml") as f:
        config_dict = yaml.safe_load(f)
    
    # Create snakemake command
    success = snakemake(
        snakefile=str("Snakefile"),
        config=config_dict,
        targets=[str(grouped_bam_path)],
        cores=1,
        verbose=True
    )

    # Run snakemake command and assert no errors
    assert success

    # Check that each read name appears twice only (once for R1 and R2)
    with pysam.AlignmentFile(grouped_bam_path, "rb") as bam:
        read_names = [read.query_name for read in bam]

    counts = Counter(read_names)

    for name, count in counts.items():
        assert count == 2, f"Read {name} appears {count} times, expected only 2"
