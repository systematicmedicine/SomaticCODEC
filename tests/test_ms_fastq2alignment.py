
"""
--- test_ms_fastq2alignment.py ---

Function for testing if a non-empty BAM can be created from raw ms fastq files

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import time

# Tests if a non-empty BAM can be created from raw ms fastq files
def test_ms_alignment_output_exists(clean_workspace_fixture):

    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_fastq2alignment",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_fastq2alignment_config.yaml",
        "--notemp",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_samples = pd.read_csv("tests/configs/test_ms_fastq2alignment_samples.csv")["ms_sample"].to_list()

    for sample in ms_samples:
        bam_path = Path("tmp") / sample / f"{sample}_markdup.bam"

        # Check if markdup bam exists
        assert bam_path.exists(), f"BAM file not found: {bam_path}"

        # Check if markdup bam is not empty
        assert bam_path.stat().st_size > 0, f"BAM file is empty: {bam_path}"