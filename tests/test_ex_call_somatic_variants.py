"""
--- test_ex_call_somatic_variants.py

Tests the rule ex_call_somatic_variants

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from utils.vcf_utils import check_vcf_structure
from pathlib import Path
import pandas as pd

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    ex_samples = pd.read_csv("tests/configs/lightweight_test_run/ex_samples.csv")["ex_sample"].to_list()

    for ex_sample in ex_samples:
        # Locate VCF file
        vcf_file = Path(f"results/{ex_sample}/{ex_sample}_variants.vcf")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)
