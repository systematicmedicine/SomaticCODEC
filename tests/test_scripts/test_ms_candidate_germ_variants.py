"""
--- test_ms_candidate_germ_variants.py

Tests the rule ms_candidate_germ_variants

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import sys

project_root = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(project_root))

from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.vcf_helpers import check_vcf_structure

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)

# Test that all variants in MS candidate VCF have alt VAF >= min_alt_vaf