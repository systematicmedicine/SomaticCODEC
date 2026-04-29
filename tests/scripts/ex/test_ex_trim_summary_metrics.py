"""
--- test_ex_trim_summary_metrics.py ---

Test that the script ex_trim_summary_metrics.py

Authors:
    - Joshua Johnstone
"""
import json
import types
from rule_scripts.ex.processing_metrics.ex_trim_summary_metrics import main

def test_trim_summary_metrics_calculation(tmp_path):

    # Define input and output paths
    demuxed_r1 = "tests/data/test_ex_trim_summary_metrics/demuxed_r1.fastq"
    demuxed_r2 = "tests/data/test_ex_trim_summary_metrics/demuxed_r2.fastq"
    trimmed_r1 = "tests/data/test_ex_trim_summary_metrics/trimmed_r1.fastq"
    trimmed_r2 = "tests/data/test_ex_trim_summary_metrics/trimmed_r2.fastq"
    output_json_path = tmp_path / "trim_summary_metrics.json"
    log_file = tmp_path / "ex_trim_summary_metrics.log"

    # Define expected values
    expected_values = {
        "pre_trim_bases": 600,
        "post_trim_bases": 420,
        "trimmed_bases": 180,
        "trimmed_bases_pct": 30,
        "zero_length_reads_r1": 1,
        "zero_length_reads_r2": 0,
        "zero_length_pct": 25
    }

    expected_percentiles = {
        "read_length_percentiles_r1": {
            "0th": 0,
            "50th": 75,
            "100th": 150
        },
        "read_length_percentiles_r2": {
            "0th": 120,
            "50th": 135,
            "100th": 150
        },
    }

    # Run script with test data
    args = types.SimpleNamespace(
        demuxed_r1 = demuxed_r1,
        demuxed_r2 = demuxed_r2,
        trimmed_r1 = trimmed_r1,
        trimmed_r2 = trimmed_r2,
        json = output_json_path,
        log = log_file
    )
    main(args=args)

    # Load output JSON
    with open(output_json_path, "r") as f:
        output_json = json.load(f)

    # Assert that output values match expected values
    for key in expected_values:
        assert output_json[key]["value"] == expected_values[key], "Output values do not match expected values"

    for read_key in ["read_length_percentiles_r1", "read_length_percentiles_r2"]:
        for percentile in expected_percentiles[read_key]:
            assert output_json[read_key]["values"][percentile] == expected_percentiles[read_key][percentile], "Output percentiles values do not match expected percentile values"
