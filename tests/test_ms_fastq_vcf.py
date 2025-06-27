
"""
--- test_ms_fastq_vcf.py ---

Function for testing the ms pipeline from raw FASTQs to a flagged VCF file

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil
import pysam

# Tests if non-empty flagged VCF files can be created from raw ms FASTQ files
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
        flagged_vcf_path = Path("tmp") / sample / f"{sample}_ms_merged_flagged.vcf.gz"

        # Check if flagged VCF exists
        assert flagged_vcf_path.exists(), f"ms_merged_flagged.vcf.gz not found: {flagged_vcf_path}"

        # Check that flagged VCF is not empty
        assert flagged_vcf_path.stat().st_size > 0, f"ms_merged_flagged.vcf.gz is empty: {flagged_vcf_path}"
