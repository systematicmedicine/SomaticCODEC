"""
--- test_ex_snv_read_position_metrics.py

Tests the script ex_snv_read_position_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import types
from rule_scripts.ex.variant_analysis.ex_snv_read_position_metrics import main

@pytest.mark.parametrize(
    "vcf_path, bam_path, bai_path, expected_percentiles",
    [
        ("tests/data/test_ex_snv_read_position_metrics/called_snvs.vcf",
         "tests/data/test_ex_snv_read_position_metrics/filtered_dsc.bam",
         "tests/data/test_ex_snv_read_position_metrics/filtered_dsc.bam.bai", {
            "0th": 30.08,
            "10th": 34.81,
            "50th": 52.08,
            "100th": 62.65
        }),
    ]
)
def test_read_position_percentiles(tmp_path, vcf_path, bam_path, bai_path, expected_percentiles):

    # Define test outputs
    output_json = tmp_path / "snv_read_pos_metrics.json"
    output_plot = tmp_path / "snv_read_pos_plot.pdf"
    log_file = tmp_path / "log.txt"

    args = types.SimpleNamespace(
        vcf = vcf_path,
        bam = bam_path,
        bai = bai_path,
        json = output_json,
        plot = output_plot,
        log = log_file
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    for percentile in expected_percentiles:
        assert result['read_position_percentiles']['values'][percentile] == expected_percentiles[percentile]