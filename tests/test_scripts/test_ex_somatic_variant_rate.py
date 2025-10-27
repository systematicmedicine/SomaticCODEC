"""
--- test_ex_somatic_variant_rate.py

Tests the script ex_somatic_variant_rate.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""
import pytest
import os
from pathlib import Path
import sys
import json

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ex_somatic_variant_rate import main
@pytest.mark.parametrize(
    "vcf_path, expected_metrics",
    [
        (
            "tests/data/test_ex_somatic_variant_rate/variants.vcf",
            {
                "starting_bases": 35,
                "min-BQ": 20,
                "min-MQ": 30,
                "filtered_bases": 0,
                "evaluated_bases": 35,
                "num_snv_bases": 11,
                "snv_rate": 0.3142857,
                "snv_per_diploid": 1905743997,
            },
        ),
        (
            "tests/data/test_ex_somatic_variant_rate/filtered_variants.vcf",
            {
                "starting_bases": 32,
                "min-BQ": 20,
                "min-MQ": 30,
                "filtered_bases": 9,
                "evaluated_bases": 23,
                "num_snv_bases": 15,
                "snv_rate": 0.6521739,
                "snv_per_diploid": 3954607210
            }
        ),
        (
            "tests/data/test_ex_somatic_variant_rate/no_variants.vcf",
            {
                "starting_bases": 0,
                "min-BQ": 20,
                "min-MQ": 30,
                "filtered_bases": 0,
                "evaluated_bases": 0,
                "num_snv_bases": 0,
                "snv_rate": 0,
                "snv_per_diploid": 0,
            }
        ),
    ]
)
def test_somatic_variant_rate(tmp_path, vcf_path, expected_metrics):
    output_file = tmp_path / "results.json"
    log_file = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"vcf_all": vcf_path})
        output = type("output", (), {"results": str(output_file)})
        log = [str(log_file)]

    main(MockSnakemake)

    # Load metrics
    metrics = {}
    with open(output_file) as f:
        metrics = json.load(f)
        metrics["starting_bases"] = int(metrics["starting_bases"])
        metrics["filtered_bases"] = int(metrics["filtered_bases"])
        metrics["evaluated_bases"] = int(metrics["evaluated_bases"])
        metrics["num_snv_bases"] = int(metrics["num_snv_bases"])
        metrics["snv_rate"] = float(metrics["snv_rate"])
        metrics["snv_per_diploid"] = float(metrics["snv_per_diploid"])
    
    if metrics["min-BQ"] != "NA":
        metrics["min-BQ"] = int(metrics["min-BQ"])
    if metrics["min-MQ"] != "NA":
        metrics["min-MQ"] = int(metrics["min-MQ"])
    
    # Test if metrics match expected values
    assert metrics["starting_bases"] == expected_metrics["starting_bases"]
    assert metrics["min-BQ"] == expected_metrics["min-BQ"]
    assert metrics["min-MQ"] == expected_metrics["min-MQ"]
    assert metrics["filtered_bases"] == expected_metrics["filtered_bases"]
    assert metrics["evaluated_bases"] == expected_metrics["evaluated_bases"]
    assert metrics["num_snv_bases"] == expected_metrics["num_snv_bases"]
    assert pytest.approx(metrics["snv_rate"], rel=1e-6) == expected_metrics["snv_rate"]
    assert pytest.approx(metrics["snv_per_diploid"], rel=1e-4) == expected_metrics["snv_per_diploid"]

    if os.path.exists(str(log_file)):
        os.remove(str(log_file))
