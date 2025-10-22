"""
--- test_ex_softclipping_metrics.py

Tests the script ex_softclipping_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_softclipping_metrics import main

@pytest.mark.parametrize(
    "bam_path, expected_total_reads, expected_0th_percentile, expected_90th_percentile, expected_100th_percentile",
    [
        ("tests/data/test_ex_softclipping_metrics/no_softclip.bam", 5, 0, 0, 0),
        ("tests/data/test_ex_softclipping_metrics/softclip.bam", 4, 0, 10, 10),
    ]
)
def test_softclipping_percentiles(tmp_path, bam_path, expected_total_reads, expected_0th_percentile, expected_90th_percentile, expected_100th_percentile):
    output_json = tmp_path / "softclip_metrics.json"
    log_file = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"dsc_final": bam_path})
        output = type("output", (), {"file_path": str(output_json)})
        log = [str(log_file)]

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["total_reads_processed"] == expected_total_reads
    percentiles = result["softclip_bases_per_read_percentiles"]
    assert percentiles["0th_percentile"] == expected_0th_percentile
    assert percentiles["90th_percentile"] == expected_90th_percentile
    assert percentiles["100th_percentile"] == expected_100th_percentile

    if os.path.exists(str(log_file)):
        os.remove(str(log_file))

