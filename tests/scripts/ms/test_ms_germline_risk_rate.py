"""
--- test_ms_germline_risk_rate.py

Tests the script ms_germline_risk_rate.py

Author: Joshua Johnstone
"""

from rule_scripts.ms.processing_metrics.ms_germline_risk_rate import main
import types
import json

# Tests that germline risk rate is calculated correctly
def test_germline_risk_rate_calculation(tmp_path):

    # Define inputs and outputs
    depth_pileup = "tests/data/test_ms_germline_risk_rate/depth_pileup.vcf"
    depth_alt_pileup = "tests/data/test_ms_germline_risk_rate/depth_alt_pileup.vcf"
    output_json_path = tmp_path / "ms_germline_risk_rate.json"
    log_file = tmp_path / "ms_germline_risk_rate.log"

    # Define expected values
    expected_values = {
        "callable_bases": 10,
        "germ_risk_positions": 2,
        "germline_risk_rate": 0.2
    }

    # Run script with test data
    args = types.SimpleNamespace(
        depth_pileup = depth_pileup,
        depth_alt_pileup = depth_alt_pileup,
        output_json = output_json_path,
        log = log_file        
    )
    main(args=args)

    # Assert that calculated values match expected values
    with open(output_json_path, "r") as f:
        output_json = json.load(f)

    for key in output_json:
        assert output_json[key]["value"] == expected_values[key], "Output values do not match expected values"
