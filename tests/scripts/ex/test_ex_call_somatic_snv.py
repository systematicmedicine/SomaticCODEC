"""
--- test_ex_call_somatic_snv.py

Tests the rule ex_call_somatic_snv

Authors:
    - Joshua Johnstone
    - Cameron Fraser
"""
from pathlib import Path
from helpers.vcf_helpers import check_vcf_structure
from helpers.get_metadata import load_config, get_ex_sample_ids
from definitions.paths.io import ex as EX

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ex_samples = get_ex_sample_ids(config)

    for ex_sample in ex_samples:
        # Locate VCF file
        vcf_file = Path(EX.CALLED_SNVS.format(ex_sample=ex_sample))

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)
