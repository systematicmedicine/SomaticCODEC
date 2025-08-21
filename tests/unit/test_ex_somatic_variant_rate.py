"""
--- test_ex_somatic_variant_rate.py

Tests the script ex_somatic_variant_rate.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import pytest
import os
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
                "snv_per_diploid": 2011428571.43,
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
                "snv_per_diploid": 4173913043.48
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
    output_file = tmp_path / "results.txt"
    log_file = tmp_path / "log.txt"

    class MockSnakemake:
        input = type("input", (), {"vcf_all": vcf_path})
        output = type("output", (), {"results": str(output_file)})
        log = [str(log_file)]

    main(MockSnakemake)

    metrics = {}
    with open(output_file) as f:
        for line in f:
            key, val = line.strip().split("\t")
            if key in ["snv_rate"]:
                metrics[key] = float(val)
            elif key in ["snv_per_diploid"]:
                metrics[key] = float(val)
            else:
                metrics[key] = val if val == "NA" else int(val)

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
