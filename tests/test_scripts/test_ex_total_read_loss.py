"""
--- test_ex_total_read_loss.py

Tests the script ex_total_read_loss.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import json
from unittest.mock import patch
from scripts.ex_total_read_loss import main

@pytest.mark.parametrize(
    "fastq1, fastq2, bam_file, expected_paired_reads, expected_final_dsc_reads, expected_percent_lost",
    [
        (
            "tests/data/test_ex_total_read_loss/input_R1.fastq",
            "tests/data/test_ex_total_read_loss/input_R2.fastq",
            "tests/data/test_ex_total_read_loss/final_dsc.bam",
            4, 2, 50.0
        )
    ]
)
def test_total_read_loss(tmp_path, fastq1, fastq2, bam_file, expected_paired_reads, expected_final_dsc_reads, expected_percent_lost):
    output_file = tmp_path / "result.json"
    log_file = tmp_path / "log.txt"

    sample_name = "TestSample"

    class MockSnakemake:
        input = type("input", (), {
            "input_fastq1": fastq1,
            "input_fastq2": fastq2,
            "dsc_final": bam_file,
        })
        params = type("params", (), {
            "sample": sample_name})
        output = type("output", (), {"file_path": str(output_file)})
        log = [str(log_file)]

    class MockCompletedProcess:
        def __init__(self, mock_file_path):
            with open(mock_file_path, "r") as f:
                self.stdout = f.read()

    def mock_run(cmd, check, capture_output, text):
        fastq_file = cmd[-1]
        if fastq_file.endswith("input_R1.fastq"):
            return MockCompletedProcess("tests/data/test_ex_total_read_loss/mock_seqkit_output_R1.txt")
        elif fastq_file.endswith("input_R2.fastq"):
            return MockCompletedProcess("tests/data/test_ex_total_read_loss/mock_seqkit_output_R2.txt")

    with patch("scripts.ex_total_read_loss.subprocess.run", side_effect=mock_run):
        main(MockSnakemake)

    with open(output_file) as f:
        result = json.load(f)

    assert result["paired_reads_post_demux"] == expected_paired_reads
    assert result["final_dsc_reads"] == expected_final_dsc_reads
    assert result["percent_reads_lost"] == expected_percent_lost


