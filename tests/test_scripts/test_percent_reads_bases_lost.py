"""
--- test_percent_reads_bases_lost.py

Tests the script percent_reads_bases_lost.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import json
from scripts.percent_reads_bases_lost import main
import pytest
import os

@pytest.mark.parametrize("pre_files, post_files, expected_pct_reads_lost, expected_pct_bases_lost,", [
    (["tests/data/test_percent_reads_bases_lost/pre.bam"], ["tests/data/test_percent_reads_bases_lost/post.bam"], 90, 90),
    (["tests/data/test_percent_reads_bases_lost/pre.fastq.gz"], ["tests/data/test_percent_reads_bases_lost/post.fastq.gz"], 0, 50)
])
def test_percent_lost_calculation(tmp_path, pre_files, post_files, expected_pct_reads_lost, expected_pct_bases_lost):
    counts_json = "tests/data/test_percent_reads_bases_lost/counts.json"
    output_json = tmp_path / "pct_lost.json"

    class MockSnakemake:
        input = type("input", (), {"counts_json": counts_json,
                                   "pre_files": pre_files,
                                   "post_files": post_files})
        output = type("output", (), {"json": str(output_json)})
        log = ["log.txt"]
        params = {}

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["pct_reads_lost"] == expected_pct_reads_lost
    assert result["pct_bases_lost"] == expected_pct_bases_lost

    if os.path.exists("log.txt"):
        os.remove("log.txt")