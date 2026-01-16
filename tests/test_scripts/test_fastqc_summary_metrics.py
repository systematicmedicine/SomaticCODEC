"""
--- test_fastqc_summary_metrics.py

Tests the script fastqc_summary_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
import shutil
import types
from scripts.global_scripts.metrics.fastqc_summary_metrics import main

@pytest.mark.parametrize(
    "fastqc_file, expected_metrics",
    [
        (
            "tests/data/test_fastqc_summary_metrics/fastqc_data.txt",
            {
                "total_reads": 10000,
                "per_sequence_quality": 39,
                "per_base_quality": 40,
                "per_tile_quality": 40,
                "read_length": 150,
                "overrepresented_sequences": 1.5,
                "gc_deviation": 9.87,
                "per_base_content_diff": 9.26,
                "per_base_N_content": 0.05
            }
        )
    ]
)
def test_fastqc_summary_metrics(tmp_path, fastqc_file, expected_metrics):
    sample_name = "TestSample"

    sample_dir = tmp_path / "metrics" / sample_name
    sample_dir.mkdir(parents=True)

    tmp_fastqc_path = sample_dir / "fastqc_data.txt"
    shutil.copy(fastqc_file, tmp_fastqc_path)

    output_json_path = sample_dir / "fastqc_data_summary.json"

    args = types.SimpleNamespace(
        fastqc_files=[tmp_fastqc_path],
        json_files=[output_json_path],
        sample="TestSample",
        log=str("log.txt")
    )
    main(args=args)

    

    with open(output_json_path) as f:
        data = json.load(f)

    for key, expected_value in expected_metrics.items():
        if isinstance(expected_value, float):
            assert data[key] == pytest.approx(expected_value, rel=1e-3)
        else:
            assert data[key] == expected_value

    if os.path.exists("log.txt"):
        os.remove("log.txt")

    



