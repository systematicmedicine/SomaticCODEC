"""
--- test_ex_duplication_metrics.py

Tests the script ex_duplication_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_duplication_metrics import main

@pytest.mark.parametrize("dedup_metrics, expected_dedup_rate", [
    ("tests/data/test_ex_duplication_metrics/dedup_metrics.txt", 0.05)
])
def test_duplication_rate_calculation(tmp_path, dedup_metrics, expected_dedup_rate):
    output_json = tmp_path / "duplication_metrics.json"
    sample = "TestSample"
    log_path = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"umi_metrics": dedup_metrics})

        output = type("output", (), {"json": str(output_json)})
        log = [str(log_path)]
        params = type("params", (), {"sample": sample})

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["duplication_rate"] == expected_dedup_rate