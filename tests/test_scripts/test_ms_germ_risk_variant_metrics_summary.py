"""
--- test_ms_germ_risk_variant_metrics_summary.py

Tests the script ms_germ_risk_variant_metrics_summary.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import shutil
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ms_germ_risk_variant_metrics_summary import main

@pytest.mark.parametrize(
    "variant_metrics_path, pileup_vcf_path, sample_name, expected_metrics",
    [
        (
            "tests/data/test_ms_germ_risk_variant_metrics_summary/variant_metrics.txt",
            "tests/data/test_ms_germ_risk_variant_metrics_summary/pileup.vcf",
            "TestSample",
            {
                "callable_bases": 4,
                "variants_called": 3,
                "germline_variant_rate": 0.75,
                "snv_indel_ratio": 2,
                "insertion_deletion_ratio": 0.92,
                "MNP_other_variants": 0,
                "transition_transversion_ratio": 1.82,
            }
        )
    ]
)
def test_ms_germ_risk_variant_metrics_summary(tmp_path, variant_metrics_path, pileup_vcf_path, sample_name, expected_metrics):

    vmp = tmp_path / "variant_metrics.txt"
    pup = tmp_path / "pileup.vcf"

    min_depth = 3

    shutil.copy(variant_metrics_path, vmp)
    shutil.copy(pileup_vcf_path, pup)

    class MockSnakemake:
        input = type("input", (), {
            "variant_metrics": str(vmp),
            "pileup_vcf": str(pup)
        })
        params = type("params", (), {"sample": sample_name,
                                     "min_depth": min_depth})
        output = type("output", (), {"summary": str(tmp_path / "summary.json")})
        log = [str(tmp_path / "log.txt")]

    main(MockSnakemake)

    with open(tmp_path / "summary.json") as f:
        data = json.load(f)

    for key, expected_value in expected_metrics.items():
        assert data[key] == pytest.approx(expected_value)


    



