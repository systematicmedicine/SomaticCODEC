"""
--- test_multimapping_read_metrics.py

Tests the script multimapping_read_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import json
import types
from rule_scripts.shared.metrics.multimapping_read_metrics import main

def test_multimapping_reads_calculation(tmp_path):

    # Define inputs and outputs
    input_bam_path = "tests/data/test_multimapping_read_metrics/input.bam"
    output_json_path = tmp_path / "multimapping_read_metrics.json"
    log_file = tmp_path / "multimapping_read_metrics.log"

    # Define expected values
    expected_values = {
        "total_reads": 10,
        "multimapping_reads": 7,
        "multimapping_pct": 70
    }

    # Run script with test data
    args = types.SimpleNamespace(
        bam = input_bam_path,
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
