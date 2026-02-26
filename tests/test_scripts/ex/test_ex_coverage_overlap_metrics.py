"""
--- test_ex_dsc_coverage_metrics.py

Tests the script ex_dsc_coverage_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import types
import json
from rule_scripts.ex.processing_metrics.ex_coverage_overlap_metrics import main

@pytest.mark.parametrize("precomputed_masks, ex_dsc_bam, include_bed, ms_bam, lowdepth_bed, germ_risk_bed, combined_bed, ref_fai, expected_values", [
    (
        ["tests/data/test_ex_coverage_overlap_metrics/gnomAD.bed",
         "tests/data/test_ex_coverage_overlap_metrics/repeat_masker.bed",
         "tests/data/test_ex_coverage_overlap_metrics/difficult_regions.bed"],
         "tests/data/test_ex_coverage_overlap_metrics/ex_dsc_anno_filtered.bam",
         "tests/data/test_ex_coverage_overlap_metrics/include_bed.txt",
         "tests/data/test_ex_coverage_overlap_metrics/ms_deduped_map.bam",
         "tests/data/test_ex_coverage_overlap_metrics/lowdepth.bed",
         "tests/data/test_ex_coverage_overlap_metrics/germ_risk.bed",
         "tests/data/test_ex_coverage_overlap_metrics/combined.bed",
         "tests/data/test_ex_coverage_overlap_metrics/ref.fna.fai",
     {
         ("include_bed", "include_bed"): 100,
         ("ref_genome", "ex_depth"): 22,
         ("ref_genome", "ms_depth"): 18.62,
         ("ms_depth", "ex_depth"): 31.05,
         ("gnomAD", "ex_BQ"): 25.57})
])
def test_ex_coverage_overlap_metrics(tmp_path, precomputed_masks, ex_dsc_bam, include_bed, ms_bam, lowdepth_bed, germ_risk_bed, combined_bed, ref_fai, expected_values):

    output_json = str(tmp_path / "ex_coverage_overlap_metrics.json")
    log = str(tmp_path / "ex_coverage_overlap_metrics.log")
    ms_depth_threshold = 1
    ex_depth_threshold = 1
    ms_bq_threshold = 1
    ex_bq_threshold = 1
    threads = 1

    args = types.SimpleNamespace(
        threads = str(threads),
        precomputed_masks = precomputed_masks,
        ex_dsc_bam = ex_dsc_bam,
        include_bed = include_bed,
        ms_bam = ms_bam,
        lowdepth_bed = lowdepth_bed,
        germ_risk_bed = germ_risk_bed,
        combined_bed = combined_bed,
        ref_fai = ref_fai,
        output_json = output_json,
        ms_depth_threshold = str(ms_depth_threshold),
        ex_depth_threshold = str(ex_depth_threshold),
        ms_bq_threshold = str(ms_bq_threshold),
        ex_bq_threshold = str(ex_bq_threshold),
        log = log
    )
    main(args=args)

    with open(output_json) as f:
        values = json.load(f)

    for (metric_a, metric_b), expected_pct in expected_values.items():
        json_key = f"{metric_a}_vs_{metric_b}"
        assert values[json_key]["pct_overlap"] == expected_pct