"""
--- ex_snv_distance_metrics.py ---

Test that the script ex_snv_distance_metrics.py works correctly

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

# Setup
from scripts.ex.variant_analysis.ex_snv_distance_metrics import calculate_nearest_snv_percentiles

# Define hard coded variables
VCF_PATH = "tests/data/test_ex_snv_distance_metrics/S00X_variants.vcf"
EXPECTED = {
        "0": 20,
        "25": 20,
        "50": 154,
        "75": 873,
        "100": 2116
        }

# Test expected values are obtained for toy VCF
def test_known_vcf_distances():
    # Run the function
    percentiles = calculate_nearest_snv_percentiles(VCF_PATH)

    # Test if values match
    for key, exp_val in EXPECTED.items():
        assert key in percentiles, f"Missing percentile {key}"
        assert percentiles[key] == exp_val, f"For percentile {key}, expected {exp_val}, got {percentiles[key]}"
