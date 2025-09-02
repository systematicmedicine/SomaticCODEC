"""
--- test_ex_germline_contamination.py

Tests the script ex_germline_contamination.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
from types import SimpleNamespace
import sys
from pathlib import Path
import shutil

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_germline_contamination import main

@pytest.mark.parametrize(
    "somatic_path, germline_path, expected_matches",
    [
        # Three overlapping variants
        (
            "tests/data/test_ex_germline_contamination/somatic_overlap.vcf",
            "tests/data/test_ex_germline_contamination/gnomad-chr21-micro.vcf.bgz",
            3
        ),
        # No overlap
        (
            "tests/data/test_ex_germline_contamination/somatic_no_overlap.vcf",
            "tests/data/test_ex_germline_contamination/gnomad-chr21-micro.vcf.bgz",
            0
        )
    ]
)
def test_ex_germline_contamination(tmp_path, somatic_path, germline_path, expected_matches):
    # --- Define input paths ---
    tmp_somatic_vcf = tmp_path / "somatic_overlap.vcf"
    shutil.copy(somatic_path, tmp_somatic_vcf)
    germline_vcf = germline_path

    # --- Prepare output paths ---
    intermediate_bgz = tmp_path / "somatic.bgz"
    intermediate_tbi = tmp_path / "somatic.bgz.tbi"
    germline_matches = tmp_path / "germline_matches.vcf"
    metrics_file = tmp_path / "metrics.json"
    log_file = tmp_path / "log.log"

    # --- Mock snakemake object ---
    snakemake = SimpleNamespace(
        input=SimpleNamespace(
            somatic_vcf=str(tmp_somatic_vcf),
            germline_vcf=str(germline_vcf)
        ),
        output=SimpleNamespace(
            intermediate_somatic_bgz=str(intermediate_bgz),
            intermediate_somatic_tbi=str(intermediate_tbi),
            germline_matches=str(germline_matches),
            metrics_file=str(metrics_file)
        ),
        log=[str(log_file)]
    )

    # --- Run the script ---
    main(snakemake)

    # --- Assertions ---
    assert germline_matches.exists()
    assert metrics_file.exists()

    # Validate metrics
    metrics = json.loads(metrics_file.read_text())
    assert metrics["germline_matches"] == expected_matches
