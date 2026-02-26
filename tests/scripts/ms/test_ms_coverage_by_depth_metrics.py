"""
--- test_ms_coverage_by_depth_metrics.py ---

Tests the script ms_coverage_by_depth_metrics.py

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import pytest
import json
import types
from rule_scripts.ms.processing_metrics.ms_coverage_by_depth_metrics import main

@pytest.mark.parametrize("depth_histogram, expected_pct_depth_40X", [
    ("tests/data/test_ms_coverage_by_depth_metrics/depth_histogram.txt", 20)
])
def test_coverage_by_depth_calculation(tmp_path, depth_histogram, expected_pct_depth_40X):
    output_json = tmp_path / "coverage_by_depth_metrics.json"
    sample = "TestSample"
    log_path = tmp_path / "log.txt"
    min_depth = 40

    args = types.SimpleNamespace(
        depth_histogram=depth_histogram,
        coverage_by_depth=output_json,
        min_depth=min_depth,
        sample=sample,
        log=log_path
    )
    main(args=args)


    with open(output_json) as f:
        result = json.load(f)

    assert result["pct_coverage_min_depth"] == expected_pct_depth_40X