
"""
--- test_pipeline.py ---

Function for testing all outputs of the full pipeline.
    - Tests that all expected files are created
    - Tests that all expected files have atleast one datapoint

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

    # Load sample and region names for file name wildcards
    ms_samples = pd.read_csv("tests/configs/test_pipeline_outputs_ms_samples.csv")["ms_sample"].to_list()
    ex_lanes = pd.read_csv("tests/configs/test_pipeline_outputs_ex_lanes.csv")["ex_lane"].to_list()
    ex_samples = pd.read_csv("tests/configs/test_pipeline_outputs_ex_samples.csv")["ex_sample"].to_list()

    # Load files to check
    file_lists = ["tests/configs/test_pipeline_outputs_files_tmp.txt",
                  "tests/configs/test_pipeline_outputs_files_metrics.txt",
                  "tests/configs/test_pipeline_outputs_files_results.txt"]
    
    outputs_to_check = sum([Path(f).read_text().splitlines() for f in file_lists],[])
    checked_files = []
    file_counts = []

    for path_str in outputs_to_check:
        if "{ms_sample}" in path_str:
            for ms_sample in ms_samples:
                checked_files.append(path_str.format(ms_sample=ms_sample))
        elif "{ex_lane}" in path_str:
            for ex_lane in ex_lanes:
                checked_files.append(path_str.format(ex_lane=ex_lane))
        elif "{ex_sample}" in path_str:
            for ex_sample in ex_samples:
                checked_files.append(path_str.format(ex_sample=ex_sample))
        else:
            checked_files.append(path_str)

    missing_files = [filepath for filepath in checked_files if not Path(filepath).exists()]
    assert not missing_files, f"Missing files: {missing_files}"

    for path in checked_files:
        path = Path(path)

        # Check that non-data files are not empty
        if path.suffix in [".amb", ".ann", ".pac", ".0123", ".64", 
                    ".fai", ".dict", ".html", ".pdf", ".json", 
                    ".zip", ".bai", ".tbi"]:
            assert path.stat().st_size > 0, f"File is empty: {path}"
            data_row_count = None
        else:
            # Check data files have data points
            data_row_count = count_data_points.count_data_points(path)
            assert data_row_count >= 1, f"File has no data points: {path}"

            # Store data point counts
            file_counts.append({
            "file_path": str(path),
            "data_row_count": data_row_count
            })

    # Print all data point counts (when using pytest -s flag)
    df_counts = pd.DataFrame(file_counts)
    with pd.option_context('display.max_rows', None, 'display.max_columns', None):
        print(df_counts)

    # Check that all files in metrics, tmp and results are being checked
    folders_to_check = ["metrics", "tmp", "results"]
    untracked_files = []

    for folder in folders_to_check:
        for path in Path(folder).rglob("*"):
            if path.is_file():
                path_str = str(path)
                if path.name.startswith("."):
                    continue
                if "tmp/downloads" in path_str:
                    continue
                if path_str not in checked_files:
                    untracked_files.append(path_str)

    assert not untracked_files, f"The following files are not being checked: {untracked_files}"
