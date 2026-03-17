"""
--- test_ex_call_dsc_read_loss.py

Tests the script ex_call_dsc_read_loss.py

Authors:
    - Joshua Johnstone
"""
import pytest
from unittest.mock import patch, MagicMock
import tempfile
import json
import os
from rule_scripts.ex.processing_metrics.ex_call_dsc_read_loss import main
import argparse

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
    # Mock behavior of subprocess.run
    def mock_run(cmd, stdout, stderr, text, check):
        mock_result = MagicMock()
        if "map_anno.bam" in cmd[-1]:
            mock_result.stdout = pre_out
        elif "unmap_dsc.bam" in cmd[-1]:
            mock_result.stdout = post_out
        return mock_result

    mock_subprocess_run.side_effect = mock_run

    # Temporary output and log files
    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as tmp_out, \
         tempfile.NamedTemporaryFile(delete=False, suffix=".log") as tmp_log:
        json_out_path = tmp_out.name
        log_path = tmp_log.name

    # Build fake argparse args
    args = argparse.Namespace(
        pre_call_bam="tmp/TestSample/TestSample_map_anno.bam",
        post_call_bam="tmp/TestSample/TestSample_unmap_dsc.bam",
        call_dsc_metrics=json_out_path,
        sample="TestSample",
        log=log_path
    )

    # Run the test
    if expect_error:
        with pytest.raises(Exception):
            main(args)
    else:
        main(args)
        with open(json_out_path) as f:
            data = json.load(f)
        assert round(data["reads_lost"], 1) == expected

    # Cleanup
    for path in [json_out_path, log_path]:
        if os.path.exists(path):
            os.remove(path)