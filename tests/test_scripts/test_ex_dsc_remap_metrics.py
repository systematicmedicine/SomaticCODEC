"""
--- test_ex_dsc_remap_metrics.py

Tests the script ex_dsc_remap_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import pytest
from unittest.mock import patch, MagicMock
import tempfile
import json
import os
from scripts.ex_dsc_remap_metrics import main
import scripts.helpers.get_metadata as md


@pytest.mark.parametrize(
    "total_reads, mapped_reads, over_min_mapq_reads, "
    "expected_pct_mapped, expected_pct_over_mapq, expected_pct_lost",
    [
        # Some reads lost
        (1000, 900, 800, 90.0, 88.9, 11.1),
        # No reads lost
        (1000, 1000, 1000, 100.0, 100.0, 0.0),
        # All reads lost to MAPQ
        (1000, 1000, 0, 100.0, 0.0, 100.0),
    ]
)
@patch("subprocess.run")
def test_read_loss_cases(
    mock_subprocess_run,
    total_reads,
    mapped_reads,
    over_min_mapq_reads,
    expected_pct_mapped,
    expected_pct_over_mapq,
    expected_pct_lost
):
    # Mock subprocess.run to return values in sequence
    def mock_run_side_effect(cmd, shell, capture_output, text):
        result = MagicMock()
        if " -c " in cmd and "-F 0x4" not in cmd and "-q" not in cmd:
            result.stdout = str(total_reads) + "\n"
        elif "-F 0x4" in cmd and "-q" not in cmd:
            result.stdout = str(mapped_reads) + "\n"
        elif "-q" in cmd:
            result.stdout = str(over_min_mapq_reads) + "\n"
        result.returncode = 0
        return result

    mock_subprocess_run.side_effect = mock_run_side_effect

    with tempfile.NamedTemporaryFile(delete=False, suffix=".json") as tmp_out:
        json_out_path = tmp_out.name

    config = md.load_config("config/config.yaml")

    class FakeSnakemake:
        class Input:
            bam = "fake.bam"
        input = Input()
        output = type("Output", (), {"metrics": json_out_path})
        class Params:
            min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"]
            sample = "TestSample"
        params = Params()
        log = ["logfile.log"]

    main(FakeSnakemake())

    with open(json_out_path) as f:
        data = json.load(f)

    assert data["percentage_mapped"] == expected_pct_mapped
    assert data["percentage_mapped_and_over_MAPQ_threshold"] == expected_pct_over_mapq
    assert data["reads_lost_to_MAPQ_filter"] == expected_pct_lost

    os.remove(json_out_path)
    if os.path.exists("logfile.log"):
        os.remove("logfile.log")
