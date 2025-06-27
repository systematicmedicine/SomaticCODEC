
"""
--- test_ex_fastq_dsc.py ---

Functions for testing that a raw codecseq fastq file provided by AGRF can be converted to a duplex strand consensus bam

Author: James Phie

"""

import subprocess
from pathlib import Path
import pandas as pd

# Tests if non-empty filter-flagged VCF files can be created from raw ms FASTQ files
def test_ex_fastq_dsc_output(clean_workspace_fixture):

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ex_fastq_dsc",
        "--cores", "all",
        "--configfile", "tests/configs/test_ex_fastq_dsc_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd, check=True)

    # Check for expected output
    ex_sample = pd.read_csv("tests/configs/test_ex_fastq_dsc_exsamples.csv")["ex_sample"].to_list()

    for sample in ex_sample:
        dsc_path = Path("tmp") / sample / f"{sample}_map_dsc_anno_filtered.bam"

        # Check if filtered dsc bam exists
        assert dsc_path.exists(), f"ex_dsc_anno_filtered.bam not found: {dsc_path}"

        # Check that filter-flagged VCF is not empty
        assert dsc_path.stat().st_size > 0, f"ex_dsc_anno_filtered.bam is empty: {dsc_path}"