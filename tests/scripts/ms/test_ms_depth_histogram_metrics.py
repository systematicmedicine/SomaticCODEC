"""
--- test_ms_depth_histogram_metrics.py ---

Tests the rule ms_depth_histogram_metrics.py

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""

import shutil
from helpers.get_metadata import load_config
from pathlib import Path
import definitions.paths.io.ms as MS
from snakemake import snakemake

def test_depth_hist_values_correct(tmp_path, lightweight_test_run):

    # Define inputs
    deduped_bam = "tests/data/test_ms_depth_histogram_metrics/deduped.bam"
    deduped_bam_bai = "tests/data/test_ms_depth_histogram_metrics/deduped.bam.bai"

    # Load config
    config = load_config(lightweight_test_run["test_config_path"])

    # Define test sample ID
    ms_sample = "SEQ0001"

    # Copy input BAM and BAI to temporary directory
    expected_bam_path = Path(MS.DEDUPED_BAM.format(ms_sample=ms_sample))
    copied_bam_path = tmp_path / expected_bam_path
    copied_bam_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(deduped_bam, copied_bam_path)

    expected_bai_path = Path(MS.DEDUPED_BAM_INDEX.format(ms_sample=ms_sample))
    copied_bai_path = tmp_path / expected_bai_path
    copied_bai_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(deduped_bam_bai, copied_bai_path)

    # Copy snakemake files to temporary directory
    shutil.copy("Snakefile", tmp_path / "Snakefile")
    shutil.copytree("rule_scripts", tmp_path / "rule_scripts")
    shutil.copytree("rules", tmp_path / "rules")
    shutil.copytree("tmp/downloads", tmp_path / "tmp/downloads")
    shutil.copytree("tests/data/lightweight_test_run/config", tmp_path / "tests/data/lightweight_test_run/config")
    shutil.copytree("definitions", tmp_path / "definitions")
    
    # Define target file
    target_depth_hist = MS.MET_DEPTH_HIST.format(ms_sample=ms_sample)

    # Define output
    output_depth_hist = tmp_path / target_depth_hist

    # Define expected output
    expected_depth_hist = "tests/data/test_ms_depth_histogram_metrics/depth_histogram_counts.txt"

    # Run snakemake inside temporary directory
    success = snakemake(
        snakefile=str(tmp_path / "Snakefile"),
        config=config,
        targets=[target_depth_hist],
        cores=1,
        verbose=True,
        workdir=str(tmp_path),
        allowed_rules=["ms_depth_histogram_metrics"]
        )

    # Assert that rule succeeded
    assert success

    # Assert that output depth histogram matches expected depth histogram
    with open(output_depth_hist) as f:
        output_lines = f.read().splitlines()

    with open(expected_depth_hist) as f:
        expected_lines = f.read().splitlines()

    assert output_lines == expected_lines, "Output depth histogram does not match expected depth histogram"
