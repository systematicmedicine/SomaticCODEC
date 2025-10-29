"""
--- test_ex_duplex_overlap_metrics.py

Tests the script ex_duplex_overlap_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_duplex_overlap_metrics import main

@pytest.mark.parametrize("bam_path, expected_0th, expected_50th, expected_100th", [
    ("tests/data/test_ex_duplex_overlap_metrics/dsc.bam", 0, 5, 10)
])
def test_duplex_overlap_calculation(tmp_path, bam_path, expected_0th, expected_50th, expected_100th):
    output_json = tmp_path / "overlap_metrics.json"

    class MockSnakemake:
        input = type("input", (), {"bam": bam_path})
        output = type("output", (), {"metrics": str(output_json)})
        log = ["log.txt"]
        params = {}

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["overlap_percentiles"]["value"]["0"] == expected_0th
    assert result["overlap_percentiles"]["value"]["50"] == expected_50th
    assert result["overlap_percentiles"]["value"]["100"] == expected_100th

    if os.path.exists("log.txt"):
        os.remove("log.txt")