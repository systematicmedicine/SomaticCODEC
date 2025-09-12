"""
--- test_ms_het_hom_ratio.py ---

Tests the script ms_het_hom_ratio.py

Authors: 
    - Joshua Johnstone
    - Chat-GPT
"""

import pytest
import json
import sys
from pathlib import Path

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ms_het_hom_ratio import main

@pytest.mark.parametrize("vcf, expected_het_hom_ratio", [
    ("tests/data/test_ms_het_hom_ratio/candidate_variants.vcf", 2.0)
])
def test_ms_het_hom_ratio_calculation(tmp_path, vcf, expected_het_hom_ratio):
    output_json = tmp_path / "het_hom_ratio.json"
    sample = "TestSample"
    het_threshold = 0.10
    log_path = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"vcf": vcf})

        output = type("output", (), {"json": str(output_json)})
        log = [str(log_path)]
        params = type("params", (), {"sample": sample,
                                     "het_threshold": het_threshold})

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["het_hom_ratio"] == expected_het_hom_ratio