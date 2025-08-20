"""
--- test_ms_candidate_germ_variants.py

Tests the rule ms_candidate_germ_variants

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from scripts.get_metadata import load_config, get_ms_sample_ids
from utils.vcf_utils import check_vcf_structure

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)