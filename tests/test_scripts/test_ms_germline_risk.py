"""
--- test_ms_germline_risk.py

Tests the rule ms_germline_risk

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

# Import libraries
from pathlib import Path
import pysam
from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.vcf_helpers import check_vcf_structure

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)

# Test that all variants in MS candidate VCF have:
# 1. alt VAF >= min_alt_vaf
# 2. depth >= min_depth
def test_germ_risk_variants_fit_criteria(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    min_alt_vaf = config["sci_params"]["ms_germline_risk"]["min_alt_vaf"]
    min_depth = config["sci_params"]["ms_low_depth_mask"]["min_depth"]

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file_path = Path(f"tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf")

        # Open VCF with pysam
        vcf_file = pysam.VariantFile(vcf_file_path)

        # Get alt VAF and depth for each variant
        for record in vcf_file:
            vcf_sample = next(iter(record.samples.values()))
            ad = vcf_sample.get("AD")
            dp = vcf_sample.get("DP")

            alt_reads = sum(ad[1:])
            vaf = alt_reads / dp if dp > 0 else 0

            # Assert variants fit criteria
            assert dp < min_depth or vaf >= min_alt_vaf, (
                f"Variant {record} does not meet masking criteria: "
                f"Record values: DP={dp}, VAF={vaf}"
                f"Criteria: min_depth < {min_depth} or min_alt_vaf >= {min_alt_vaf}"
                )
