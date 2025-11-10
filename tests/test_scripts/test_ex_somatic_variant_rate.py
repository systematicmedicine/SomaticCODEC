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
import json
import types
from scripts.ex.variant_analysis.ex_somatic_variant_rate import main
@pytest.mark.parametrize(
    "vcf_path, expected_metrics",
    [
        (
            "tests/data/test_ex_somatic_variant_rate/variants.vcf",
            {
                "starting_bases": {"value": 35},
                "min-BQ": {"value": 20},
                "min-MQ": {"value": 30},
                "filtered_bases": {"value": 0},
                "evaluated_bases": {"value": 35},
                "num_snv_bases": {"value": 11},
                "snv_rate": {"value": 0.3142857},
                "snv_per_diploid": {"value": 1905743997},
            },
        ),
        (
            "tests/data/test_ex_somatic_variant_rate/filtered_variants.vcf",
            {
                "starting_bases": {"value": 32},
                "min-BQ": {"value": 20},
                "min-MQ": {"value": 30},
                "filtered_bases": {"value": 9},
                "evaluated_bases": {"value": 23},
                "num_snv_bases": {"value": 15},
                "snv_rate": {"value": 0.6521739},
                "snv_per_diploid": {"value": 3954607210},
            },
        ),
        (
            "tests/data/test_ex_somatic_variant_rate/no_variants.vcf",
            {
                "starting_bases": {"value": 0},
                "min-BQ": {"value": 20},
                "min-MQ": {"value": 30},
                "filtered_bases": {"value": 0},
                "evaluated_bases": {"value": 0},
                "num_snv_bases": {"value": 0},
                "snv_rate": {"value": 0},
                "snv_per_diploid": {"value": 0},
            },
        ),
    ]
)

def test_somatic_variant_rate(tmp_path, vcf_path, expected_metrics):
    output_file = tmp_path / "results.json"
    log_file = tmp_path / "log.txt"

    # Run script
    args = types.SimpleNamespace(
        vcf_all=vcf_path,
        results=output_file,
        log=log_file
        )
    main(args=args)

    # Load metrics
    metrics = {}
    with open(output_file) as f:
        metrics = json.load(f)
    
    if metrics["min-BQ"]["value"] != "NA":
        metrics["min-BQ"]["value"] = int(metrics["min-BQ"]["value"])
    if metrics["min-MQ"]["value"] != "NA":
        metrics["min-MQ"]["value"] = int(metrics["min-MQ"]["value"])
    
    # Test if metrics match expected values
    assert metrics["starting_bases"]["value"] == expected_metrics["starting_bases"]["value"]
    assert metrics["min-BQ"]["value"] == expected_metrics["min-BQ"]["value"]
    assert metrics["min-MQ"]["value"] == expected_metrics["min-MQ"]["value"]
    assert metrics["filtered_bases"]["value"] == expected_metrics["filtered_bases"]["value"]
    assert metrics["evaluated_bases"]["value"] == expected_metrics["evaluated_bases"]["value"]
    assert metrics["num_snv_bases"]["value"] == expected_metrics["num_snv_bases"]["value"]
    assert pytest.approx(metrics["snv_rate"]["value"], rel=1e-6) == expected_metrics["snv_rate"]["value"]
    assert pytest.approx(metrics["snv_per_diploid"]["value"], rel=1e-4) == expected_metrics["snv_per_diploid"]["value"]

    if os.path.exists(str(log_file)):
        os.remove(str(log_file))
