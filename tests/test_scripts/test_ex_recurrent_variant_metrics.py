"""
--- test_ex_recurrent_variant_metrics.py

Tests the script ex_recurrent_variant_metrics.py

Authors:
    - Cameron Fraser
"""

# Imports
import sys
import json
from math import isclose
from pathlib import Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))
from ex_recurrent_variant_metrics import main

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
    main(
        somatic_vcf_paths = TEST_DATA["somatic_vcfs"],
        germ_contaminant_vcf_paths = TEST_DATA["germline_contaminant_vcfs"],
        output_metrics_path = str(tmp_path / "metrics.json"),
        output_vcf_path = str(tmp_path / "recurrent.vcf"),
        log_path = str(tmp_path / "log.txt"),
    )

    # Load output metrics
    with open(tmp_path / "metrics.json") as f:
        metrics = json.load(f)

    # Check individual values (edit as per your expectations)
    assert metrics["total_variants_before_filtering"]["value"] == 15
    assert metrics["total_variants_after_filtering"]["value"] == 12
    assert metrics["total_unique_variants_after_filtering"]["value"] == 6
    assert metrics["total_recurrent_variants_after_filtering"]["value"] == 9
    assert isclose(metrics["percentage_recurrent_variants"]["value"], 75, rel_tol=1e-6)