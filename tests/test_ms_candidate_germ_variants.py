"""
--- test_ms_candidate_germ_variants.py

Tests the rule ms_candidate_germ_variants

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
from utils.vcf_utils import check_vcf_structure

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    ms_samples = pd.read_csv("tests/configs/lightweight_test_run/ms_samples.csv")["ms_sample"].to_list()

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)