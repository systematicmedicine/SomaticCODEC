"""
--- test_ms_candidate_variant_metrics_summary.py

Tests the script ms_candidate_variant_metrics_summary.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import shutil
from scripts.ms_candidate_variant_metrics_summary import main

@pytest.mark.parametrize(
    "variant_metrics_path, fai_path, het_hom_ratio_path, sample_name, expected_metrics",
    [
        (
            "tests/data/test_ms_candidate_variant_metrics_summary/variant_metrics.txt",
            "tests/data/test_ms_candidate_variant_metrics_summary/reference.fai",
            "tests/data/test_ms_candidate_variant_metrics_summary/ms_het_hom_ratio.txt",
            "TestSample",
            {
                "germline_variant_rate": 0.0025,
                "snv_indel_ratio": 9,
                "insertion_deletion_ratio": 0.92,
                "MNP_other_variants": 3,
                "transition_transversion_ratio": 1.82,
                "het_hom_ratio": 0.10
            }
        )
    ]
)
def test_ms_candidate_variant_metrics_summary(tmp_path, variant_metrics_path, fai_path, het_hom_ratio_path, sample_name, expected_metrics):

    vmp = tmp_path / "variant_metrics.txt"
    fp = tmp_path / "reference.fai"
    hhp = tmp_path / "ms_het_hom_ratio.txt"

    shutil.copy(variant_metrics_path, vmp)
    shutil.copy(fai_path, fp)
    shutil.copy(het_hom_ratio_path, hhp)

    class MockSnakemake:
        input = type("input", (), {
            "variant_metrics": str(vmp),
            "fai": str(fp),
            "ms_het_hom_ratio": str(hhp)
        })
        params = type("params", (), {"sample": sample_name})
        output = type("output", (), {"summary": str(tmp_path / "summary.json")})
        log = [str(tmp_path / "log.txt")]

    main(MockSnakemake)

    with open(tmp_path / "summary.json") as f:
        data = json.load(f)

    for key, expected_value in expected_metrics.items():
        assert data[key] == pytest.approx(expected_value)


    



