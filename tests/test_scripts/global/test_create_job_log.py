"""
--- test_create_job_log.py

Tests the script create_job_log.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import csv
import pytest
import shutil
import types
from scripts.global_scripts.metrics.create_job_log import main

@pytest.mark.parametrize(
    "log_file_path, expected_num_jobs",
    [
        ("tests/data/test_create_job_log/snakemake.log", 7),
    ]
)
def test_job_log_parametrized(tmp_path, log_file_path, expected_num_jobs):
    # Copy the log file to temporary test directory
    tmp_log = tmp_path / "snakemake.log"
    shutil.copy(log_file_path, tmp_log)
    tmp_csv = tmp_path / "jobs.csv"

    # Run the script
    args = types.SimpleNamespace(
        run_pipeline_log=tmp_log,
        job_log_csv=tmp_csv,
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    # Read CSV and verify structure
    with open(tmp_csv) as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    assert len(rows) == expected_num_jobs

    # Check each row has required columns
    for row in rows:
        assert "jobid" in row
        assert "rule" in row
        assert "start_time" in row
        assert "finish_time" in row