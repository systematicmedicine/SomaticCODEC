"""
--- test_ex_depth_metrics.py

Tests the script ex_depth_metrics.py

Authors:
    - Joshua Johnstone
"""
import pytest
import json
import types
from rule_scripts.ex.processing_metrics.ex_depth_metrics import main

@pytest.mark.parametrize("bam_ex_dsc, include_bed, ref_fai, expected_depth_percentiles, expected_pct_coverage", [
    ("tests/data/test_ex_depth_metrics/ex_dsc_anno_filtered.bam",
     "tests/data/test_ex_depth_metrics/include_bed.txt",
     "tests/data/test_ex_depth_metrics/ref.fna.fai",
     {("0th", 2),
      ("50th", 2),
      ("100th", 2)},
     {("1X", 12),
      ("2X", 12),
      ("10X", 0),
      ("100X", 0)})
])
def test_ex_depth_metrics(tmp_path, bam_ex_dsc, include_bed, ref_fai, expected_depth_percentiles, expected_pct_coverage):

    output_json = str(tmp_path / "ex_depth_metrics.json")
    log = str(tmp_path / "ex_depth_metrics.log")
    ex_bq_threshold = 70
    threads = 1

    args = types.SimpleNamespace(
        threads = threads,
        ex_dsc_bam = bam_ex_dsc,
        include_bed = include_bed,
        ref_fai = ref_fai,
        output_json = output_json,
        ex_bq_threshold = ex_bq_threshold,
        log = log
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    # Assert depth percentile values are correct
    for percentile, expected_val in expected_depth_percentiles:
        assert result['depth_percentiles']['values'][percentile] == expected_val, f"For {percentile} percentile: expected {expected_val}, got {result['depth_percentiles']['values'][percentile]}"

    # Assert pct coverage values are correct
    for threshold, expected_val in expected_pct_coverage:
        assert result['pct_coverage']['values'][threshold] == expected_val, f"For {threshold} pct coverage: expected {expected_val}, got {result['pct_coverage']['values'][threshold]}"
