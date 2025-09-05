"""
--- test_ms_coverage_by_depth_metrics.py ---

Tests the script ms_coverage_by_depth_metrics.py

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import pytest
import json
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ms_coverage_by_depth_metrics import main

@pytest.mark.parametrize("depth_histogram, expected_pct_depth_40X", [
    ("tests/data/test_ms_coverage_by_depth_metrics/depth_histogram.txt", 20)
])
def test_coverage_by_depth_calculation(tmp_path, depth_histogram, expected_pct_depth_40X):
    output_json = tmp_path / "coverage_by_depth_metrics.json"
    sample = "TestSample"
    log_path = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"depth_histogram": depth_histogram})
        output = type("output", (), {"coverage_by_depth": str(output_json)})
        log = [str(log_path)]
        params = type("params", (), {"sample": sample})

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["pct_coverage"]["40X"] == expected_pct_depth_40X