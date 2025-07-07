
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

    files_to_copy = [f"GRCh38_Chr21.fna",
                     f"ms_Chr21_10000reads_r1.fastq.gz",
                     f"ms_Chr21_10000reads_r2.fastq.gz",
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
    outputs_to_check = pd.read_csv("tests/configs/ms_output_files.csv")

    for ms_sample in ms_samples:
        # Check intermediate files
        for _, row in outputs_to_check[outputs_to_check["file_type"] == "intermediate"].iterrows():
            path_str = row["file_path"].format(ms_sample=ms_sample) if "{ms_sample}" in row["file_path"] else row["file_path"]
            path = Path(path_str)

            # Check that file exists
            assert path.exists(), f"Missing file: {path}"

            # Check that file is not empty
            assert path.stat().st_size > 0, f"Empty file: {path}"

            # Check that intermediate files have data rows
            if path.suffix in [".bed"]:
                try:
                    df = pd.read_csv(path, sep="\t", comment="#", header = None)
                    assert len(df) > 0, f"File has header but no data rows: {path}"
                except pd.errors.EmptyDataError:
                    assert False, f"File has header but no data rows: {path}"
        
        # Check metrics files
        for _, row in outputs_to_check[outputs_to_check["file_type"] == "metric"].iterrows():
            path_str = row["file_path"].format(ms_sample=ms_sample) if "{ms_sample}" in row["file_path"] else row["file_path"]
            path = Path(path_str)

            # Check that file exists
            assert path.exists(), f"Missing file: {path}"

            # Check that file is not empty
            assert path.stat().st_size > 0, f"Empty file: {path}"    
        