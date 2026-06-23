"""
--- test_clonality_metrics.py

Tests the script clonality_metrics.py

Authors:
    - Joshua Johnstone
"""
import pytest
import types
import json
from rule_scripts.shared.metrics.clonality_metrics import main

@pytest.mark.parametrize(
    "vcf_path, expected_values",
    [
        ("tests/data/test_clonality_metrics/pileup_depth_AD_0_40.vcf", {"total_snvs": 40,
                                                        "unique_snvs": 0,
                                                        "pct_unique_snvs": 0,
                                                        "clonal_snvs": 40,
                                                        "pct_clonal_snvs": 100}),
        ("tests/data/test_clonality_metrics/pileup_depth_AD_40_0.vcf", {"total_snvs": 0,
                                                        "unique_snvs": 0,
                                                        "pct_unique_snvs": 0,
                                                        "clonal_snvs": 0,
                                                        "pct_clonal_snvs": 0}),
        ("tests/data/test_clonality_metrics/pileup_depth_AD_50pct_clonal.vcf", {"total_snvs": 10,
                                                        "unique_snvs": 5,
                                                        "pct_unique_snvs": 50,
                                                        "clonal_snvs": 5,
                                                        "pct_clonal_snvs": 50}),                      
    ]
)
def test_clonality_metrics(tmp_path, vcf_path, expected_values):
    # Define temporary output paths
    tmp_log = tmp_path / "clonality_metrics.log"
    tmp_json = tmp_path / "clonality_metrics.json"

    # Run the script
    args = types.SimpleNamespace(
        vcf=vcf_path,
        json=tmp_json,
        log=tmp_log
    )
    main(args=args)

    # Load JSON output
    with open(tmp_json) as f:
        result = json.load(f)

    # Assert that the output values match the expected values
    for key, expected in expected_values.items():
        assert result[key]["value"] == expected, f"Output {key} of {result[key]['value']} != expected value of {expected}."