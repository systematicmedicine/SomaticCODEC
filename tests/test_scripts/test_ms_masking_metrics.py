"""
--- test_ms_masking_metrics.py

Tests the script ms_masking_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
from types import SimpleNamespace
import pytest
from scripts.ms_masking_metrics import main 

@pytest.mark.parametrize("input_files, expected_percentages", [
    (
        {
            "precomputed_masks": ["tests/data/test_ms_masking_metrics/gnomad.bed", 
                             "tests/data/test_ms_masking_metrics/giab.bed"],
            "ms_lowdepth_bed": "tests/data/test_ms_masking_metrics/lowdepth.bed",
            "ms_germ_del_bed": "tests/data/test_ms_masking_metrics/germ_del.bed",
            "ms_germ_ins_bed": "tests/data/test_ms_masking_metrics/germ_ins.bed",
            "ms_germ_snv_bed": "tests/data/test_ms_masking_metrics/germ_snv.bed",
            "combined_bed": "tests/data/test_ms_masking_metrics/combined.bed",
            "ref_index": "tests/data/test_ms_masking_metrics/reference.fai",
        },
        {
            "gnomad": 2.5,
            "giab": 5.0,
            "lowdepth": 0.25,
            "germ_deletions": 12.5,
            "germ_insertions": 17.5,
            "germ_snvs": 0.02,
            "combined_mask": 100
        }
    )
])
def test_masking_metrics(tmp_path, input_files, expected_percentages):
    log_path = tmp_path / "masking_metrics.log"
    intermediate_sorted = tmp_path / "intermediate_sorted.bed"
    intermediate_merged = tmp_path / "intermediate_merged.bed"
    output_json = tmp_path / "mask_metrics.json"

    mock_snakemake = SimpleNamespace(
        input=SimpleNamespace(**input_files),
        params=SimpleNamespace(sample="TestSample"),
        log=[str(log_path)],
        output=SimpleNamespace(
            intermediate_sorted=str(intermediate_sorted),
            intermediate_merged=str(intermediate_merged),
            mask_metrics=str(output_json)
        )
    )

    main(mock_snakemake)

    with open(tmp_path / "mask_metrics.json") as f:
        data = json.load(f)

    for key, expected_value in expected_percentages.items():
        assert data["mask_files"][key]["percentage_of_ref_genome"] == pytest.approx(expected_value)
