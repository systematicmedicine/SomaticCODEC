"""
--- test_ex_gnomAD_overlap.py

Tests the script ex_gnomAD_overlap.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import types
from scripts.ex.variant_analysis.ex_gnomAD_overlap import main

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

    # --- Run the script ---
    args = types.SimpleNamespace(
        somatic_vcf=somatic_path,
        somatic_all_vcf=somatic_all_path,
        germline_vcf=germline_path,
        intermediate_somatic_bgz=intermediate_bgz,
        intermediate_somatic_tbi=intermediate_tbi,
        germline_matches=germline_matches,
        metrics_file=metrics_file,
        log=log_file
    )
    main(args=args)

    # --- Assertions ---
    assert germline_matches.exists()
    assert metrics_file.exists()

    # Validate metrics
    metrics = json.loads(metrics_file.read_text())
    assert metrics["total_gnomAD_matches"]["value"] == expected_matches
