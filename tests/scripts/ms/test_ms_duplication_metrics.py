"""
--- test_ms_duplication_metrics.py ---

Tests the script ms_duplication_metrics.py

Authors: 
    - Joshua Johnstone
"""
import pytest
import json
import types
from rule_scripts.ms.processing_metrics.ms_duplication_metrics import main

@pytest.mark.parametrize("dedup_metrics, expected_dedup_rate", [
    ("tests/data/test_ms_duplication_metrics/dedup_metrics.json", 0.05)
])
def test_duplication_rate_calculation(tmp_path, dedup_metrics, expected_dedup_rate):
    output_json = tmp_path / "duplication_metrics.json"
    sample = "TestSample"
    log_path = tmp_path / "log.txt"

    args = types.SimpleNamespace(
        dedup_metrics=dedup_metrics,
        duplication_metrics=output_json,
        sample=sample,
        log=log_path
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    assert result["duplication_rate"] == expected_dedup_rate