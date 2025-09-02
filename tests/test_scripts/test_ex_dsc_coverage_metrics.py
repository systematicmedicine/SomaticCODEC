"""
--- test_ex_dsc_coverage_metrics.py

Tests the script ex_dsc_coverage_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
from types import SimpleNamespace
from unittest.mock import patch, MagicMock
import io
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_dsc_coverage_metrics import main

@pytest.mark.parametrize("ms_depth_path, include_bed_path, ex_dsc_depth_path, ref_fai_path, expected_values", [
    # Typical input
    ("tests/data/test_ex_dsc_coverage_metrics/ms_depth_per_base.txt", 
     "tests/data/test_ex_dsc_coverage_metrics/include_bed.txt",
     "tests/data/test_ex_dsc_coverage_metrics/ex_dsc_depth.txt",
     "tests/data/test_ex_dsc_coverage_metrics/ref.fna.fai",
     {"total_genome_positions": 10,
      "include_bed_total_positions": 8,
      "coverage_overlap_ex_ms": 50,
      "ex_duplex_coverage": 40,
      "include_bed_coverage": 80,
      "ex_mean_analyzable_duplex_depth": 0.5,
      "ex_dsc_coverage_bedregions": 50,
      "ex_dsc_coverage_wholegenome": 40})
])
@patch("subprocess.Popen")
def test_ex_dsc_coverage_metrics(mock_popen, ms_depth_path, include_bed_path, ex_dsc_depth_path, ref_fai_path, expected_values, tmp_path):
    output_path = tmp_path / "metrics.json"
    log_path = tmp_path / "log.txt"

    # Read ex_dsc_depth_path file contents as list of lines (simulate samtools depth output)
    with open(ex_dsc_depth_path, "r") as f:
        ex_dsc_content = f.read()

    mock_proc = MagicMock()
    mock_proc.stdout = io.StringIO(ex_dsc_content)
    mock_proc.wait.return_value = 0
    mock_popen.return_value = mock_proc

    class FakeSnakemake:
        input = SimpleNamespace(
            bam_ex_dsc=ex_dsc_depth_path,
            ms_depth=ms_depth_path,
            include_bed=include_bed_path,
            fai=ref_fai_path,
        )
        output = SimpleNamespace(
            metrics=str(output_path),
        )
        params = SimpleNamespace(
            quality_threshold=20,
            sample="TestSample",
            ms_depth_threshold=10,
        )
        log = [str(log_path)]

    main(FakeSnakemake())

    with open(output_path) as f:
        result = json.load(f)

    for key, expected_val in expected_values.items():
        assert key in result, f"{key} missing from output"
        assert result[key] == expected_val, f"{key}: expected {expected_val}, got {result[key]}"

    if log_path.exists():
        log_path.unlink()