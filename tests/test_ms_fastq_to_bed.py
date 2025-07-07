
"""
--- test_ms_fastq_to_bed.py ---

Function for testing the ms pipeline from raw FASTQs to a combined mask BED file

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil

# Tests if non-empty BED and metrics files can be created from raw ms FASTQ files
def test_ms_outputs(clean_workspace_fixture):

# Copy files into tmp/downloads
    target_dir = Path("tmp/downloads")
    target_dir.mkdir(exist_ok=True)

    files_to_copy = [f"micro_GRCh38_Chr1_1Mbp.fna",
                     f"ms_Chr1_100reads_r1.fastq.gz",
                     f"ms_Chr1_100reads_r2.fastq.gz",
                     f"GRCh38_alldifficultregions_10lines.bed",
                     f"gnomad_common_af01_merged_10lines.bed"
                     ]

    for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_ms_outputs",
        "--cores", "all",
        "--configfile", "tests/configs/test_ms_outputs_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Load sample names
    ms_samples = pd.read_csv("tests/configs/test_ms_outputs_samples.csv")["ms_sample"].to_list()

    # Load files to check
    files_to_check = pd.read_csv("tests/configs/ms_intermediate_files.csv")

    for sample in ms_samples:
        for _, row in files_to_check.iterrows():
            path_str = row["file_path"].format(sample=sample) if "{sample}" in row["file_path"] else row["file_path"]
            path = Path(path_str)

            # Check that file exists
            assert path.exists(), f"Missing file: {path}"

            # Check that file is not empty
            assert path.stat().st_size > 0, f"Empty file: {path}"

            # Check that tabular files have data rows
            if path.suffix in [".csv", ".tsv", ".txt"]:
                sep = "\t" if path.suffix in [".tsv", ".txt"] else ","
                df = pd.read_csv(path, sep=sep, comment="#")
                assert len(df) > 0, f"File has no data rows: {path}"


    
        