"""
--- test_ex_trimmed_read_length_metrics.py ---

Test that the script ex_trimmed_read_length_metrics.py works correctly for FASTQ files with known read lengths

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
import tempfile
import types
from scripts.ex.processing_metrics.ex_trimmed_read_length_metrics import main

@pytest.mark.parametrize(
    "r1_path, r2_path, expected_0th_percentile, expected_50th_percentile, expected_100th_percentile, expected_percent_zero_length",
    [("tests/data/test_ex_trimmed_read_length_metrics/r1.fq", 
      "tests/data/test_ex_trimmed_read_length_metrics/r2.fq",
       145,
       147,
       150,
       25.0)
    ]
)
def test_trimmed_read_length_metrics_real_fastqs(tmp_path, r1_path, r2_path, expected_0th_percentile, expected_50th_percentile, expected_100th_percentile, expected_percent_zero_length):
    # Temporary output JSON
    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as tmp_out:
        json_out_path = tmp_out.name

    # Run script
    args = types.SimpleNamespace(
        r1=r1_path,
        r2=r2_path,
        json=json_out_path,
        sample="TestSample",
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    # Load output JSON
    with open(json_out_path) as f:
        data = json.load(f)

    # Assertions
    assert data["length_percentiles_r1"]["0th"] == expected_0th_percentile
    assert data["length_percentiles_r1"]["50th"] == expected_50th_percentile
    assert data["length_percentiles_r1"]["100th"] == expected_100th_percentile
    assert data["percent_zero_length"] == expected_percent_zero_length
