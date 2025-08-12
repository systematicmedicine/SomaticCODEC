"""
--- test_ex_fastp_filter_summary_metrics.py

Tests the script ex_fastp_filter_summary_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
from scripts.ex_fastp_filter_summary_metrics import main

@pytest.mark.parametrize(
    "json_length_path, json_meanquality_path, expected_filtered_length, expected_filtered_meanquality",
    [
        (
            "tests/data/test_ex_fastp_filter_summary_metrics/filter_meanquality_metrics_20pct.json",
            "tests/data/test_ex_fastp_filter_summary_metrics/filter_readlength_metrics_10pct.json",
            20,   # expected reads_filtered_length %
            10    # expected reads_filtered_meanquality %
        ),
        (
            "tests/data/test_ex_fastp_filter_summary_metrics/filter_meanquality_metrics_0pct.json",
            "tests/data/test_ex_fastp_filter_summary_metrics/filter_readlength_metrics_100pct.json",
            0,   # expected reads_filtered_length %
            100    # expected reads_filtered_meanquality %
        )
    ]
)
def test_fastp_filter_summary_metrics(tmp_path, json_length_path, json_meanquality_path, expected_filtered_length, expected_filtered_meanquality):
    output_json = tmp_path / "fastp_filter_summary.json"

    class MockSnakemake:
        input = type("input", (), {
            "json_length": json_length_path,
            "json_meanquality": json_meanquality_path,
        })
        output = type("output", (), {"filter_summary_metrics": str(output_json)})
        log = [str(tmp_path / "log.txt")]
        class Params:
            sample = "TestSample"
        params = Params()

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["reads_filtered_length"] == expected_filtered_length
    assert result["reads_filtered_meanquality"] == expected_filtered_meanquality

    if os.path.exists(str(tmp_path / "log.txt")):
        os.remove(str(tmp_path / "log.txt"))
