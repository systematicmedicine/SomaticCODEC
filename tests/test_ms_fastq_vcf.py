
"""
--- test_ms_fastq_vcf.py ---

Functions for testing the ms pipeline from raw FASTQ to VCF files

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd

# Tests if non-empty filter-flagged VCF files can be created from raw ms FASTQ files
def test_ms_flagged_vcf_output(clean_workspace_fixture):

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_flagged_vcf_output",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_flagged_vcf_output_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_sample = pd.read_csv("tests/configs/test_ms_flagged_vcf_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        flagged_vcf_path = Path("tmp") / sample / f"{sample}_ms_merge_filtered.vcf.gz"

        # Check if filter-flagged VCF exists
        assert flagged_vcf_path.exists(), f"ms_merge_filtered.vcf.gz not found: {flagged_vcf_path}"

        # Check that filter-flagged VCF is not empty
        assert flagged_vcf_path.stat().st_size > 0, f"_ms_merge_filtered.vcf.gz is empty: {flagged_vcf_path}"

# Tests if a filtered VCF can be be created from a filter-flagged VCF
def test_ms_filtered_vcf_output(clean_workspace_fixture):

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_filtered_vcf_output",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_filtered_vcf_output_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_sample = pd.read_csv("tests/configs/test_ms_filtered_vcf_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        filter_flag_vcf_path = Path("tmp") / sample / f"{sample}_ms_merge_filtered.vcf.gz"

        # Check if filter-flagged VCF exists
        assert filter_flag_vcf_path.exists(), f"ms_merge_filtered.vcf.gz not found: {filter_flag_vcf_path}"

        # Check that filter-flagged VCF is not empty
        assert filter_flag_vcf_path.stat().st_size > 0, f"_ms_merge_filtered.vcf.gz is empty: {filter_flag_vcf_path}"