"""
--- test_ex_call_dsc_metrics.py

Tests the script ex_call_dsc_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
from unittest.mock import patch, MagicMock
import tempfile
import json
import os
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_call_dsc_metrics import main

@pytest.mark.parametrize("pre_out, post_out, expected, expect_error", [
    # Some reads lost
    ("1000\n", "850\n", 15.0, False),
    # No reads lost
    ("1000\n", "1000\n", 0.0, False),
    # All reads lost
    ("1000\n", "0\n", 100.0, False),
    # No reads pre call dsc
    ("0\n", "100\n", None, True),
    # No reads pre or post call dsc
    ("0\n", "0\n", None, True),
    # Invalid pre reads
    ("not-a-number\n", "850\n", None, True),
    # Invalid post reads
    ("1000\n", "not-a-number\n", None, True)
])
@patch("subprocess.run")
def test_read_loss_cases(mock_subprocess_run, pre_out, post_out, expected, expect_error):
    # Setup mock behavior
    def mock_run(cmd, stdout, stderr, text, check):
        mock_result = MagicMock()
        if "pre" in cmd[-1]:
            mock_result.stdout = pre_out
        elif "post" in cmd[-1]:
            mock_result.stdout = post_out
        return mock_result

    mock_subprocess_run.side_effect = mock_run

    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as tmp_out:
        json_out_path = tmp_out.name

    # Create fake snakemake object
    class FakeSnakemake:
        input = {
            "pre_call_bam": "fake_pre.bam",
            "post_call_bam": "fake_post.bam"
        }
        output = {
            "call_dsc_metrics": json_out_path
        }
        params = {
            "sample": "TestSample"
        }
        log = ["logfile.log"]

    if expect_error:
        with pytest.raises(Exception):
            main(FakeSnakemake())
    else:
        main(FakeSnakemake())
        with open(json_out_path) as f:
            data = json.load(f)
        assert round(data["reads_lost"], 1) == expected

    os.remove(json_out_path)

    if os.path.exists("logfile.log"):
        os.remove("logfile.log")
