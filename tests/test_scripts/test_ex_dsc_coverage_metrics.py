"""
--- test_ex_dsc_coverage_metrics.py

Tests the script ex_dsc_coverage_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import types
from scripts.ex.processing_metrics.ex_dsc_coverage_metrics import main

@pytest.mark.parametrize("bam_ex_dsc, include_bed, ref_fai, expected_values", [
    ("tests/data/test_ex_dsc_coverage_metrics/ex_dsc_anno_filtered.bam",
     "tests/data/test_ex_dsc_coverage_metrics/include_bed.txt",
     "tests/data/test_ex_dsc_coverage_metrics/ref.fna.fai",
     {"total_genome_positions": 800,
      "ex_dsc_coverage_pct": 22,
      "ex_dsc_high_qual_pct": 6,
      "ex_dsc_high_qual_unmasked_pct": 1})
])
def test_ex_dsc_coverage_metrics(tmp_path, bam_ex_dsc, include_bed, ref_fai, expected_values):

    output_json = str(tmp_path / "dsc_coverage_metrics.json")
    output_plot = str(tmp_path / "dsc_coverage_plot.html")
    log = str(tmp_path / "log.log")
    ex_depth_threshold = 1
    ex_bq_threshold = 70
    threads = 1

    args = types.SimpleNamespace(
        threads = threads,
        ex_dsc_bam = bam_ex_dsc,
        include_bed = include_bed,
        ref_fai = ref_fai,
        output_json = output_json,
        output_plot = output_plot,
        ex_depth_threshold = ex_depth_threshold,
        ex_bq_threshold = ex_bq_threshold,
        log = log
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    for key, expected_val in expected_values.items():
        assert result[key]["value"] == expected_val, f"{key}: expected {expected_val}, got {result[key]['value']}"
