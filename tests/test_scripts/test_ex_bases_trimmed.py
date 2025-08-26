"""
--- test_ex_bases_trimmed.py ---

Test that the script ex_bases_trimmed.py works correctly for synthetic FASTQ files with a known number of trimmed bases

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
from pathlib import Path
import sys
import pytest

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_bases_trimmed import main

@pytest.mark.parametrize("pre_r1_path, pre_r2_path, post_r1_path, post_r2_path, expected_bases_trimmed, expected_pct_trimmed", [
    ("tests/data/test_ex_bases_trimmed/pre_r1.fq", 
     "tests/data/test_ex_bases_trimmed/pre_r2.fq",
     "tests/data/test_ex_bases_trimmed/post_r1.fq",
     "tests/data/test_ex_bases_trimmed/post_r2.fq",
     75,
     12.5)
     ])
def test_bases_trimmed_real_fastqs(tmp_path, pre_r1_path, pre_r2_path, post_r1_path, post_r2_path, expected_bases_trimmed, expected_pct_trimmed):
    # Temporary output JSON file
    json_out = tmp_path / "output.json"

    # Mock Snakemake object
    class FakeSnakemake:
        input = {
            "pre_r1": str(pre_r1_path),
            "pre_r2": str(pre_r2_path),
            "post_r1": str(post_r1_path),
            "post_r2": str(post_r2_path)
        }
        output = {"json": str(json_out)}
        params = {"sample": "TestSample"}
        log = [str(tmp_path / "log.log")]

    # Run script using mocked Snakemake
    main(FakeSnakemake())

    # Read JSON output
    with open(json_out) as f:
        data = json.load(f)

    # Check that number/percent bases trimmed matches expected values
    assert data["trimmed_bases"] == expected_bases_trimmed
    assert data["percent_bases_trimmed"] == expected_pct_trimmed