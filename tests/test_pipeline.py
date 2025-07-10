
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
    outputs_to_check = pd.read_csv("tests/configs/test_pipeline_outputs_file_list.csv")
    checked_files = []
    file_counts = []

    for _, row in outputs_to_check.iterrows():
        if "{ms_sample}" in row["file_path"]:
            for ms_sample in ms_samples:
                checked_files.append(row["file_path"].format(ms_sample=ms_sample))
        elif "{ex_lane}" in row["file_path"]:
            for ex_lane in ex_lanes:
                checked_files.append(row["file_path"].format(ex_lane=ex_lane))
        elif "{ex_sample}" in row["file_path"]:
            for ex_sample in ex_samples:
                checked_files.append(row["file_path"].format(ex_sample=ex_sample))
        else:
            checked_files.append(row["file_path"])

    missing_files = [filepath for filepath in checked_files if not Path(filepath).exists()]
    assert not missing_files, f"Missing files: {missing_files}"

    for path in checked_files:
        path = Path(path)
    
        # Check that file exists
        assert path.exists(), f"Missing file: {path}"

        # Check that non-data files are not empty
        if path.suffix in [".amb", ".ann", ".pac", ".0123", ".64", 
                    ".fai", ".dict", ".html", ".pdf", ".json", 
                    ".zip", ".bai"]:
            assert path.stat().st_size > 0, f"File is empty: {path}"
            data_row_count = None
        else:
            # Check data files have data points
            data_row_count = count_data_points.count_data_points(path)
            assert data_row_count >= 1, f"File has no data points: {path}"

            # Store data point count
            file_counts.append({
            "file_path": str(path),
            "data_row_count": data_row_count
            })

    # Print all data point counts clearly
    df_counts = pd.DataFrame(file_counts)
    print(df_counts)
