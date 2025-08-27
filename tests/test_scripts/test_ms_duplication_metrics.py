"""
--- test_ms_duplication_metrics.py ---

Tests the script ms_duplication_metrics.py

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""
import pytest
import json
from scripts.ms_duplication_metrics import main

@pytest.mark.parametrize("dedup_metrics, expected_dedup_rate", [
    ("tests/data/test_ms_duplication_metrics/dedup_metrics.txt", 0.05)
])
def test_duplication_rate_calculation(tmp_path, dedup_metrics, expected_dedup_rate):
    output_json = tmp_path / "duplication_metrics.json"
    sample = "TestSample"
    log_path = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"dedup_metrics": dedup_metrics})

        output = type("output", (), {"duplication_metrics": str(output_json)})
        log = [str(log_path)]
        params = type("params", (), {"sample": sample})

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["duplication_rate"] == expected_dedup_rate