"""
--- test_ex_call_somatic_snv.py

Tests the rule ex_call_somatic_snv

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from utils.vcf_utils import check_vcf_structure
from pathlib import Path
from scripts.get_metadata import load_config, get_ex_sample_ids

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config("config/config.yaml")
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:
        # Locate VCF file
        vcf_file = Path(f"results/{ex_sample}/{ex_sample}_variants.vcf")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)
