
"""
--- test_ms_fastq_vcf.py ---

Functions for testing the ms pipeline from raw FASTQ to VCF files

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil
import pysam

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
        assert flagged_vcf_path.stat().st_size > 0, f"ms_merge_filtered.vcf.gz is empty: {flagged_vcf_path}"

# Tests if a filtered VCF can be be created from a filter-flagged VCF
def test_ms_filtered_vcf_output(clean_workspace_fixture):

     # Copy flagged VCF file and index into S001/tmp directory
    ms_sample = pd.read_csv("tests/configs/test_ms_filtered_vcf_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:

        target_dir = Path("tmp") / sample
        target_dir.mkdir(exist_ok=True)

        files_to_copy = [f"{sample}_ms_merge_filtered.vcf.gz",
                         f"{sample}_ms_merge_filtered.vcf.gz.tbi"]

        for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

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
    for sample in ms_sample:
        filtered_vcf_path = Path("tmp") / sample / f"{sample}_ms_filter_pass_variants.vcf.gz"

        # Check if filtered VCF exists
        assert filtered_vcf_path.exists(), f"ms_filter_pass_variants.vcf.gz not found: {filtered_vcf_path}"

        # Check that filtered VCF is not empty
        assert filtered_vcf_path.stat().st_size > 0, f"ms_filter_pass_variants.vcf.gz is empty: {filtered_vcf_path}"

        # Check that filtered VCF contains only two of the 3 unfiltered variants
        with pysam.VariantFile(filtered_vcf_path) as vcf:
            variant_count = sum(1 for _ in vcf)

        assert variant_count == 2, f"Expected 2 variants after filtering, but found {variant_count}"