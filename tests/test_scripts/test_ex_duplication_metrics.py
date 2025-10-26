"""
--- test_ex_duplication_metrics.py

Tests the script ex_duplication_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
from scripts.ex_duplication_metrics import main

@pytest.mark.parametrize("hist_path, expected_dup_rate, expected_pct_unique", [
    ("tests/data/test_ex_duplication_metrics/map_umi_metrics_100pct_unique.txt", 0, 100),
    ("tests/data/test_ex_duplication_metrics/map_umi_metrics_90pct_unique.txt", 10, 90),
    ("tests/data/test_ex_duplication_metrics/map_umi_metrics_50pct_unique.txt", 50, 50),
    ("tests/data/test_ex_duplication_metrics/map_umi_metrics_0pct_unique.txt", 100, 0)
])
def test_duplication_metrics(tmp_path, hist_path, expected_dup_rate, expected_pct_unique):
    output_json = tmp_path / "duplication_metrics.json"

    class MockSnakemake:
        input = type("input", (), {"umi_metrics": hist_path})
        output = type("output", (), {"json": str(output_json)})
        log = [str(tmp_path / "log.txt")]
        class Params:
            sample = "TestSample"
        params = Params()

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["duplication_rate"] == expected_dup_rate
    assert result["pct_unique_reads"] == expected_pct_unique

    if os.path.exists(str(tmp_path / "log.txt")):
        os.remove(str(tmp_path / "log.txt"))