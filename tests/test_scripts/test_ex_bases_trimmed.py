"""
--- test_ex_bases_trimmed.py ---

Test that the script ex_bases_trimmed.py works correctly for synthetic FASTQ files with a known number of trimmed bases

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import types

from scripts.ex.processing_metrics.ex_bases_trimmed import main

@pytest.mark.parametrize("pre_r1, pre_r2, post_r1, post_r2, expected_trimmed, expected_pct", [
    ("tests/data/test_ex_bases_trimmed/pre_r1.fq", 
     "tests/data/test_ex_bases_trimmed/pre_r2.fq", 
     "tests/data/test_ex_bases_trimmed/post_r1.fq", 
     "tests/data/test_ex_bases_trimmed/post_r2.fq", 
     75, 
     12.5)
])
def test_bases_trimmed(tmp_path, pre_r1, pre_r2, post_r1, post_r2, expected_trimmed, expected_pct):
    args = types.SimpleNamespace(
        pre_r1=pre_r1,
        pre_r2=pre_r2,
        post_r1=post_r1,
        post_r2=post_r2,
        json=str(tmp_path / "output.json"),
        sample="TestSample",
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    with open(tmp_path / "output.json") as f:
        data = json.load(f)

    assert data["trimmed_bases"] == expected_trimmed
    assert data["percent_bases_trimmed"] == expected_pct