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
import types
from scripts.ms.processing_metrics.ms_germ_risk_variant_metrics_summary import main

@pytest.mark.parametrize(
    "variant_metrics_path, pileup_vcf_path, sample_name, expected_metrics",
    [
        (
            "tests/data/test_ms_germ_risk_variant_metrics_summary/variant_metrics.txt",
            "tests/data/test_ms_germ_risk_variant_metrics_summary/pileup.bcf",
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
    pup = tmp_path / "pileup.bcf"
    min_depth = 3
    output_json = tmp_path / "summary.json"

    shutil.copy(variant_metrics_path, vmp)
    shutil.copy(pileup_vcf_path, pup)

    args = types.SimpleNamespace(
        variant_metrics=str(vmp),
        pileup_bcf=str(pup),
        summary=str(output_json),
        min_depth=min_depth,
        sample="TestSample",
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    with open(output_json) as f:
        data = json.load(f)

    for key, expected_value in expected_metrics.items():
        assert data[key] == pytest.approx(expected_value)


    



