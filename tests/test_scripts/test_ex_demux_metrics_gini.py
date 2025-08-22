"""
--- test_ex_demux_metrics_gini.py

Tests the script ex_demux_metrics_gini.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
from scripts.ex_demux_counts_and_gini import main
import pytest
import os

@pytest.mark.parametrize("demux_path, expected_gini", [
    ("tests/data/test_ex_demux_metrics_gini/demux_metrics_gini_0.txt", 0.0),
    ("tests/data/test_ex_demux_metrics_gini/demux_metrics_gini_0.25.txt", 0.25),
    ("tests/data/test_ex_demux_metrics_gini/demux_metrics_gini_0.5.txt", 0.5),
])
def test_gini_coeff_calculation(tmp_path, demux_path, expected_gini):
    output_json = tmp_path / "demux_gini.json"

    class MockSnakemake:
        input = type("input", (), {"demux_metrics": demux_path})
        output = type("output", (), {"demux_gini": str(output_json)})
        log = ["log.txt"]
        params = {}

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["gini_coefficient"] == pytest.approx(expected_gini, abs=0.01)

    if os.path.exists("log.txt"):
        os.remove("log.txt")