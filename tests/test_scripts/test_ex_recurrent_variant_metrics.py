"""
--- test_ex_recurrent_variant_metrics.py

Tests the script ex_recurrent_variant_metrics.py

Authors:
    - Cameron Fraser
"""

# Imports
import json
from math import isclose
import types
from scripts.ex.variant_analysis.ex_recurrent_variant_metrics import main

# Create dictionary of paths to test data
DATA_DIR = "tests/data/test_ex_recurrent_variant_metrics/"
TEST_DATA = {
    "somatic_vcfs": [
        DATA_DIR + "somatic_1.vcf",
        DATA_DIR + "somatic_2.vcf",
        DATA_DIR + "somatic_3.vcf"
    ],
    "germline_contaminant_vcfs": [
        DATA_DIR + "germ_contaminants.vcf"
    ]
}

# Test script rpduces expected values
def test_ex_recurrent_variant_metrics(tmp_path):

    # Run script
    args = types.SimpleNamespace(
        somatic_vcfs=TEST_DATA["somatic_vcfs"],
        germ_contaminant_vcfs=TEST_DATA["germline_contaminant_vcfs"],
        vcf_path=str(tmp_path / "recurrent.vcf"),
        metrics_path=str(tmp_path / "metrics.json"),
        log=str(tmp_path / "log.txt")
    )
    main(args=args)

    # Load output metrics
    with open(tmp_path / "metrics.json") as f:
        metrics = json.load(f)

    # Check individual values (edit as per your expectations)
    assert metrics["total_variants_before_filtering"]["value"] == 15
    assert metrics["total_variants_after_filtering"]["value"] == 12
    assert metrics["total_unique_variants_after_filtering"]["value"] == 6
    assert metrics["total_recurrent_variants_after_filtering"]["value"] == 9
    assert isclose(metrics["percentage_recurrent_variants"]["value"], 75, rel_tol=1e-6)