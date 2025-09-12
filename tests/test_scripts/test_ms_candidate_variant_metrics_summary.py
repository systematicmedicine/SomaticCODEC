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
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ms_candidate_variant_metrics_summary import main

@pytest.mark.parametrize(
    "mask_metrics_path, variant_metrics_path, het_hom_ratio_path, depth_hist_path, sample_name, expected_metrics",
    [
        (
            "tests/data/test_ms_candidate_variant_metrics_summary/mask_metrics.json",
            "tests/data/test_ms_candidate_variant_metrics_summary/variant_metrics.txt",
            "tests/data/test_ms_candidate_variant_metrics_summary/ms_het_hom_ratio.json",
            "tests/data/test_ms_candidate_variant_metrics_summary/depth_histogram.txt",
            "TestSample",
            {
                "callable_bases": 3000000,
                "variants_called": 5000,
                "germline_variant_rate": 0.0017,
                "snv_indel_ratio": 9,
                "insertion_deletion_ratio": 0.92,
                "MNP_other_variants": 3,
                "transition_transversion_ratio": 1.82,
                "het_hom_ratio": 1.20
            }
        )
    ]
)
def test_ms_candidate_variant_metrics_summary(tmp_path, mask_metrics_path, variant_metrics_path, het_hom_ratio_path, depth_hist_path, sample_name, expected_metrics):

    mmp = tmp_path / "mask_metrics.json"
    vmp = tmp_path / "variant_metrics.txt"
    hhp = tmp_path / "ms_het_hom_ratio.json"
    dhp = tmp_path / "depth_histogram.txt"

    min_depth = 1

    shutil.copy(mask_metrics_path, mmp)
    shutil.copy(variant_metrics_path, vmp)
    shutil.copy(het_hom_ratio_path, hhp)
    shutil.copy(depth_hist_path, dhp)

    class MockSnakemake:
        input = type("input", (), {
            "variant_metrics": str(vmp),
            "ms_het_hom_ratio": str(hhp),
            "mask_metrics": str(mmp),
            "depth_hist": str(dhp)
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


    



