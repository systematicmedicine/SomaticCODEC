
"""
--- test_ms_fastq_vcf.py ---

Function for testing the ms pipeline from raw FASTQs to a candidate variant VCF file

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd

# Tests if non-empty candidate variant VCF files can be created from raw ms FASTQ files
def test_ms_candidate_vcf_output(clean_workspace_fixture):

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_candidate_vcf_output",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_candidate_vcf_output_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_sample = pd.read_csv("tests/configs/test_ms_candidate_vcf_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        flagged_vcf_path = Path("tmp") / sample / f"{sample}_ms_candidate_variants.vcf.gz"

        # Check if candidate variant VCF exists
        assert flagged_vcf_path.exists(), f"ms_candidate_variants.vcf.gz not found: {flagged_vcf_path}"

        # Check that candidate variant VCF is not empty
        assert flagged_vcf_path.stat().st_size > 0, f"ms_candidate_variants.vcf.gz is empty: {flagged_vcf_path}"
