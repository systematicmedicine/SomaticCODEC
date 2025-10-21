"""
--- test_ex_gnomAD_overlap.py

Tests the script ex_gnomAD_overlap.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
from types import SimpleNamespace
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_gnomAD_overlap import main

@pytest.mark.parametrize(
    "somatic_path, somatic_all_path, germline_path, expected_matches, expected_overlap_rate",
    [
        # Three overlapping variants
        (
            "tests/data/test_ex_gnomAD_overlap/somatic_overlap.vcf",
            "tests/data/test_ex_gnomAD_overlap/somatic_all_overlap.vcf",
            "tests/data/test_ex_gnomAD_overlap/gnomad-chr21-micro.vcf.bgz",
            3,
            0.3
        ),
        # No overlap
        (
            "tests/data/test_ex_gnomAD_overlap/somatic_no_overlap.vcf",
            "tests/data/test_ex_gnomAD_overlap/somatic_all_no_overlap.vcf",
            "tests/data/test_ex_gnomAD_overlap/gnomad-chr21-micro.vcf.bgz",
            0,
            0
        )
    ]
)
def test_ex_gnomAD_overlap(tmp_path, somatic_path, somatic_all_path, germline_path, expected_matches, expected_overlap_rate):

    # --- Prepare output paths ---
    intermediate_bgz = tmp_path / "somatic.bgz"
    intermediate_tbi = tmp_path / "somatic.bgz.tbi"
    germline_matches = tmp_path / "germline_matches.vcf"
    metrics_file = tmp_path / "metrics.json"
    log_file = tmp_path / "log.log"

    # --- Mock snakemake object ---
    snakemake = SimpleNamespace(
        input=SimpleNamespace(
            somatic_vcf=str(somatic_path),
            somatic_all_vcf=str(somatic_all_path),
            germline_vcf=str(germline_path)
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
    assert metrics["total_gnomAD_matches"]["value"] == expected_matches
    assert metrics["rate_gnomAD_overlap"]["value"] == expected_overlap_rate
