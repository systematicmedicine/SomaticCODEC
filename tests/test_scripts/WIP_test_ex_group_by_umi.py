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
import pytest
from snakemake import snakemake
import shutil
import yaml
from collections import Counter

def test_MI_bam_tag_added():
    # Locate all post-UMI grouping BAM files
    post_files = glob.glob("tmp/*/*_map_umi_grouped.bam")

    for bam_path in post_files:
        all_reads_have_MI = True
        with pysam.AlignmentFile(bam_path, "rb") as bam:
            for read in bam:
                if not read.has_tag("MI"):
                    print(f"Read {read.query_name} is missing MI")
                    all_reads_have_MI = False
        
        assert all_reads_have_MI == True, (f"BAM file {bam} has reads without MI tags")

@pytest.mark.parametrize("map_correct_path", [ #### CHANGE TO MAP ANNO
    ("tests/data/test_ex_annotate_map/map_correct_unmapped_reads.bam"),
    ("tests/data/test_ex_annotate_map/map_correct_secondary_supplemental_reads.bam"),
    ("tests/data/test_ex_annotate_map/map_correct_primary_mapped.bam"),
    #("tests/data/test_ex_annotate_map/map_correct_two_R1_one_r2.bam")
     ])
def test_group_by_umi(tmp_path, map_correct_path):
    ex_sample = "EX001"

    # Copy input BAM to temporary directory
    expected_input_path = Path(f"tmp/{ex_sample}/{ex_sample}_map_correct.bam")
    copied_input_path = tmp_path / expected_input_path
    copied_input_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(map_correct_path, copied_input_path)

    # Define target BAM
    target_bam = f"tmp/{ex_sample}/{ex_sample}_map_umi_grouped.bam"

    # Copy snakemake files to temporary directory
    shutil.copy("Snakefile", tmp_path / "Snakefile")
    shutil.copytree("scripts", tmp_path / "scripts")
    shutil.copytree("rules", tmp_path / "rules")
    shutil.copytree("config", tmp_path / "config")
    
    # Run snakemake inside temporary directory
    # Load config
    with open(tmp_path / "config/config.yaml") as f:
        config_dict = yaml.safe_load(f)

    success = snakemake(
        snakefile=str(tmp_path / "Snakefile"),
        config=config_dict,
        targets=[target_bam],
        cores=1,
        verbose=True,
        workdir=str(tmp_path)
            )

    assert success

    # Check that each read name appears twice only (once for R1 and R2)
    with pysam.AlignmentFile(tmp_path / target_bam, "rb") as bam:
        read_names = [read.query_name for read in bam]

    counts = Counter(read_names)

    for name, count in counts.items():
        assert count == 2, f"Read {name} appears {count} times, expected only 2"