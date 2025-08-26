"""
--- test_ex_percent_eligible_N_bases.py

Tests the script ex_percent_eligible_N_bases.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import pytest
import json
from types import SimpleNamespace
from pathlib import Path
import shutil
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]  # assumes scripts/ is directly under PROJECT_ROOT
sys.path.insert(0, str(PROJECT_ROOT))

from scripts.ex_percent_eligible_N_bases import main

@pytest.mark.parametrize(
    "pre_bam_path, post_bam_path, include_bed_path, expected_pre_consensus_percent_N, expected_post_consensus_percent_N",
    [
        (
            "tests/data/test_ex_percent_eligible_N_bases/pre_consensus_N.bam",
            "tests/data/test_ex_percent_eligible_N_bases/post_consensus_N.bam",
            "tests/data/test_ex_percent_eligible_N_bases/include.bed",
            40,
            10
        ),
        (
            "tests/data/test_ex_percent_eligible_N_bases/pre_consensus_no_N.bam",
            "tests/data/test_ex_percent_eligible_N_bases/post_consensus_no_N.bam",
            "tests/data/test_ex_percent_eligible_N_bases/include.bed",
            0,
            0
        )
    ]
)
def test_percent_N_calculation(tmp_path, pre_bam_path, post_bam_path, include_bed_path, expected_pre_consensus_percent_N, expected_post_consensus_percent_N):
    # --- Copy BAM and BED files to tmp_path ---
    tmp_pre_bam = tmp_path / "pre_consensus.bam"
    tmp_post_bam = tmp_path / "post_consensus.bam"
    tmp_include_bed = tmp_path / "include.bed"

    shutil.copy(pre_bam_path, tmp_pre_bam)
    shutil.copy(post_bam_path, tmp_post_bam)
    shutil.copy(include_bed_path, tmp_include_bed)

    # --- Prepare output paths ---
    json_out = tmp_path / "percent_N_bases.json"
    log_file = tmp_path / "log.txt"

    # --- Mock snakemake object ---
    snakemake = SimpleNamespace(
        input=SimpleNamespace(
            pre_dsc_bam=str(tmp_pre_bam),
            post_dsc_bam=str(tmp_post_bam),
            include_bed=str(tmp_include_bed)
        ),
        output=SimpleNamespace(
            json=str(json_out)
        ),
        params=SimpleNamespace(
            sample="test_sample",
            min_base_quality_pre_dsc=20,
            min_base_quality_post_dsc=20
        ),
        log=[str(log_file)]
    )

    # --- Run the script ---
    main(snakemake)

    # --- Assertions ---
    data = json.loads(json_out.read_text())

    # Assert that calculated percentages match expected percentages
    assert data["pre_consensus_percent_N"] == expected_pre_consensus_percent_N
    assert data["post_consensus_percent_N"] == expected_post_consensus_percent_N
