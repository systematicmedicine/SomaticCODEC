
"""
--- test_component_metrics_report.py ---

Function for testing if a non-empty component metrics report can be generated

Author: Joshua Johnstone

"""

import subprocess
from pathlib import Path
import pandas as pd
import shutil
import pysam

# Tests if non-empty component metrics report can be created
def test_component_metrics_report_output(clean_workspace_fixture):

    # Create empty metrics directories
    metrics_dir_S001 = Path("metrics/S001")
    metrics_dir_S001.mkdir(exist_ok=True)

    metrics_dir_lane1 = Path("metrics/lane1")
    metrics_dir_lane1.mkdir(exist_ok=True)

    # Copy mask metrics file
    shutil.copy(Path("tests/data/S001_mask_metrics.txt"), Path("metrics/S001/S001_mask_metrics.txt"))

    # Run snakemake
    snakemake_cmd = [
        "snakemake",
        "-s", "tests/snakefiles/Snakefile_test_component_metrics_report_output",
        "--cores", "all",
        "--configfile", "tests/configs/test_component_metrics_report_output_config.yaml",
        "--notemp",
        "--forceall",
        "--rerun-incomplete"
    ]

    subprocess.run(snakemake_cmd)

    # Check for expected output
    ms_sample = pd.read_csv("tests/configs/test_component_metrics_report_output_samples.csv")["ms_sample"].to_list()

    for sample in ms_sample:
        component_metrics_path = Path("metrics/component_metrics_report.csv")

        # Check if component metrics report exists
        assert component_metrics_path.exists(), f"component_metrics_report.csv not found: {component_metrics_path}"

        # Check that component metrics report is not empty
        assert component_metrics_path.stat().st_size > 0, f"component_metrics_report.csv is empty: {component_metrics_path}"
