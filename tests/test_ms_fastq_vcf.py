
"""
--- test_ms_fastq_vcf.py ---

Function for testing if non-empty filtered vcf files can be created from raw ms fastq files

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd

# Tests if non-empty filtered vcf files can be created from raw ms fastq files
def test_ms_vcf_output_exists(clean_workspace_fixture):

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_fastq_vcf",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_fastq_vcf_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_sample = pd.read_csv("tests/configs/test_ms_fastq_vcf_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        filtered_vcf_path = Path("tmp") / sample / f"{sample}_ms_filter_pass_variants.vcf.gz"

        # Check if filtered vcf exists
        assert filtered_vcf_path.exists(), f"ms_filter_pass_variants not found: {filtered_vcf_path}"

        # Check that filtered vcf is not empty
        assert filtered_vcf_path.stat().st_size > 0, f"ms_filter_pass_variants is empty: {filtered_vcf_path}"
