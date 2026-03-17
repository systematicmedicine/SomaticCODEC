"""
--- test_ex_snv_read_position_metrics.py

Tests the script ex_snv_read_position_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import types
import json
from rule_scripts.ex.variant_analysis.ex_snv_read_position_metrics import main

@pytest.mark.parametrize(
    "vcf_path, bam_path, bai_path, expected_mean_difference, expected_max_difference",
    [
        ("tests/data/test_ex_snv_read_position_metrics/called_snvs.vcf",
         "tests/data/test_ex_snv_read_position_metrics/filtered_dsc.bam",
         "tests/data/test_ex_snv_read_position_metrics/filtered_dsc.bam.bai",
         0.066,
         0.191)
    ]
)
def test_read_position_percentiles(tmp_path, vcf_path, bam_path, bai_path, expected_mean_difference, expected_max_difference):

    # Define test outputs
    output_json_path = tmp_path / "snv_read_pos_uniformity.json"
    output_plot_path = tmp_path / "snv_read_pos_plot.pdf"
    log_file_path = tmp_path / "log.txt"

    args = types.SimpleNamespace(
        vcf = vcf_path,
        bam = bam_path,
        bai = bai_path,
        json = output_json_path,
        plot = output_plot_path,
        log = log_file_path
    )
    main(args=args)

    # Load output JSON
    with open(output_json_path) as f:
        output = json.load(f)

    # Assert that output values match expected values
    assert output["cdf_mean_difference"]["value"] == expected_mean_difference
    assert output["cdf_max_difference"]["value"] == expected_max_difference
    