"""
--- test_ex_chromosomal_variant_rate_metrics.py

Tests the script ex_chromosomal_variant_rate_metrics.py

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
import json
import pytest
import os
import types
from scripts.ex.variant_analysis.ex_chromosomal_variant_rate_metrics import main

@pytest.mark.parametrize("vcf_path, expected_gini", [
    ("tests/data/test_ex_chromosomal_variant_rate_metrics/gini_0.vcf", 0.0),
    ("tests/data/test_ex_chromosomal_variant_rate_metrics/gini_0.25.vcf", 0.25),
    ("tests/data/test_ex_chromosomal_variant_rate_metrics/gini_0.5.vcf", 0.5),
])
def test_gini_coeff_calculation(tmp_path, vcf_path, expected_gini):
    fai_path = "tests/data/test_ex_chromosomal_variant_rate_metrics/ref.fna.fai"
    output_json = tmp_path / "chrom_variants.json"
    included_chroms = ["chr1", "chr2"]

    args = types.SimpleNamespace(
        vcf=vcf_path,
        fai=fai_path,
        metrics=output_json,
        included_chromosomes=included_chroms,
        log=str(tmp_path / "log.log")
    )
    main(args=args)

    with open(output_json) as f:
        result = json.load(f)

    assert result["gini_coefficient"] == expected_gini

    if os.path.exists("log.txt"):
        os.remove("log.txt")