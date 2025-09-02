"""
--- test_ex_recurrent_variant_metrics.py

Tests the script ex_recurrent_variant_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import glob
import os
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_recurrent_variant_metrics import main

def test_find_recurrent_variants(tmp_path):
    vcf_paths = glob.glob("tests/data/test_ex_recurrent_variant_metrics/*.vcf")
    output_json = tmp_path / "recurrent_variants.json"

    class MockSnakemake:
        input = type("input", (), {"vcfs": vcf_paths})
        output = type("output", (), {"metrics": str(output_json)})
        log = ["log.txt"]
        params = {}

    main(MockSnakemake)

    with open(output_json) as f:
        result = json.load(f)

    assert result["total_variant_calls"] == 6
    assert result["total_distinct_variants"] == 4
    assert result["total_recurrent_variants"] == 1
    assert result["pct_recurrent_variants"] == 25

    if os.path.exists("log.txt"):
        os.remove("log.txt")