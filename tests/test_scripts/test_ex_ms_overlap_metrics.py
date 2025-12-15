"""
--- test_ex_ms_overlap_metrics.py

Tests the script ex_ms_overlap_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import types
from scripts.ex.processing_metrics.ex_ms_overlap_metrics import main

@pytest.mark.parametrize("ex_dsc_bam, ms_bam, ref_fai, expected_values", [
    ("tests/data/test_ex_ms_overlap_metrics/ex_dsc_anno_filtered.bam",
     "tests/data/test_ex_ms_overlap_metrics/ms_deduped_map.bam",
     "tests/data/test_ex_ms_overlap_metrics/ref.fna.fai",
     {"ex_or_ms_bases": 248,
      "ex_and_ms_pct": 31.05,
      "ex_only_pct": 39.92,
      "ms_only_pct": 29.03})
])
def test_ex_ms_overlap_metrics(tmp_path, ex_dsc_bam, ms_bam, ref_fai, expected_values):

    output_json = str(tmp_path / "ex_ms_overlap_metrics.json")
    log = str(tmp_path / "log.log")
    ms_depth_threshold = 1

    args = types.SimpleNamespace(
        ex_dsc_bam = ex_dsc_bam,
        ms_bam = ms_bam,
        ref_fai = ref_fai,
        json = output_json,
        ms_depth_threshold = ms_depth_threshold,
        log = log
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    for key, expected_val in expected_values.items():
        assert result[key]["value"] == expected_val, f"{key}: expected {expected_val}, got {result[key]['value']}"