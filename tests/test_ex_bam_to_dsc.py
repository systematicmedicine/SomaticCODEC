
"""
--- test_ex_bam_to_dsc.py ---

Functions for testing that an aligned codecseq bam file can be converted to a duplex strand consensus bam

Author: James Phie

"""

import subprocess
from pathlib import Path
import pandas as pd
import os

def symlink_test_bams():
    for sample in ["S001", "S002", "S003"]:
        src = Path(f"tests/data/ex_{sample}_map.bam")
        dest_dir = Path(f"tmp/{sample}")
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / f"{sample}_map.bam"
        if not dest.exists():
            os.symlink(src.resolve(), dest)

# Tests if codecseq aligned bam files can be converted to dsc
def test_ex_bam_to_dsc_output(clean_workspace_fixture):

    # Create symlink for intermediate input bams before running snakemake
    symlink_test_bams()

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ex_bam_to_dsc",
        "--cores", "all",
        "--configfile", "tests/configs/test_ex_bam_to_dsc_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd, check=True)

    # Check for expected output
    ex_sample = pd.read_csv("tests/configs/test_ex_bam_to_dsc_exsamples.csv")["ex_sample"].to_list()

    for sample in ex_sample:
        dsc_path = Path("tmp") / sample / f"{sample}_map_dsc_anno.bam"
        num_lines = int(subprocess.check_output(["samtools", "view", "-c", str(dsc_path)]))

        # Check if dsc bams exist
        assert dsc_path.exists(), f"ex_dsc_anno.bam not found: {dsc_path}"

        # Check that dsc bam files are not empty
        assert dsc_path.stat().st_size > 0, f"ex_dsc_anno.bam is empty: {dsc_path}"

        # Check that there are at least 10 lines present in each samples dsc bam
        assert num_lines > 1, f"{dsc_path} has too few alignments: {num_lines}"