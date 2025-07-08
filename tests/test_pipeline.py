
"""
--- test_pipeline.py ---

Function for testing all outputs of the full pipeline.

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil
import count_data_points

# Tests if all pipeline output files can be created from raw FASTQ files
def test_pipeline_outputs(clean_workspace_fixture):

    # Copy files into tmp/downloads
    target_dir = Path("tmp/downloads")
    target_dir.mkdir(exist_ok=True)

    files_to_copy = [f"GRCh38_Chr21.fna",
                     f"ms_Chr21_10000reads_r1.fastq.gz",
                     f"ms_Chr21_10000reads_r2.fastq.gz",
                     f"GRCh38_alldifficultregions_10lines.bed",
                     f"gnomad_common_af01_merged_10lines.bed",
                     f"ex_Chr21_10000reads_r1.fastq.gz",
                     f"ex_Chr21_10000reads_r2.fastq.gz"
                     ]

    for filename in files_to_copy:
            source = Path("tests/data") / filename
            dest = target_dir / filename
            shutil.copy(source, dest)

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_pipeline_outputs",
        "--cores", "all",
        "--configfile", "tests/configs/test_pipeline_outputs_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Load sample names
    ms_samples = pd.read_csv("tests/configs/test_pipeline_outputs_samples.csv")["ms_sample"].to_list()
    ex_lanes = pd.read_csv("tests/configs/test_pipeline_outputs_samples.csv")["ex_lane"].to_list()
    ex_samples = pd.read_csv("tests/configs/test_pipeline_outputs_samples.csv")["ex_sample"].to_list()

    # Load files to check
    outputs_to_check = pd.read_csv("tests/configs/test_pipeline_outputs_file_list.csv")
    checked_files = set()

    for sample in ms_samples + ex_lanes + ex_samples:
        # Check output files
        for _, row in outputs_to_check.iterrows():
            path_str = (
                row["file_path"].format(ms_sample=sample)
                if "{ms_sample}" in row["file_path"] else
                row["file_path"].format(ex_lane=sample)
                if "{ex_lane}" in row["file_path"] else
                row["file_path"].format(ex_sample=sample)
                if "{ex_sample}" in row["file_path"] else
                row["file_path"]
                )
            
            checked_files.add(path_str)
            path = Path(path_str)

            # Check that file exists
            assert path.exists(), f"Missing file: {path}"

            # Check that non-data files are not empty
            if path.suffix in [".amb", ".ann", ".bwt.2bit.64", ".pac", ".0123", 
                               ".fai", ".dict", ".html", ".pdf", ".json", ".zip",
                               ".bai"]:
                assert path.stat().st_size > 0, f"File is empty: {path}"
            else:
                # Check that data files have data points
                data_row_count = count_data_points.count_data_points(path)
                assert data_row_count > 1, f"File has no data points ({data_row_count}): {path_str}"

    # Check that all files in the file list have been checked
    all_files = count_data_points.get_all_file_paths(outputs_to_check, ms_samples, ex_lanes, ex_samples)
    missing_files = all_files - checked_files
    assert not missing_files, f"Files from file list not checked: {missing_files}"
