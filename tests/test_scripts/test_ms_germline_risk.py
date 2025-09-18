"""
--- test_ms_germline_risk.py

Tests the rule ms_germline_risk

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

# Import libraries
from pathlib import Path
import sys
import pysam
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
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf")

        # Check for correct VCF structure
        check_vcf_structure(vcf_file)

# Test that all variants in MS candidate VCF have alt VAF >= min_alt_vaf
def test_variant_alt_vaf_over_min():
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)
    min_alt_vaf = config["rules"]["ms_germline_risk"]["min_alt_vaf"]

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file_path = Path(f"tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf")

        # Open VCF with pysam
        vcf_file = pysam.VariantFile(vcf_file_path)

        # Get alt VAF for each variant
        for record in vcf_file:
            vcf_sample = next(iter(record.samples.values()))
            ad = vcf_sample.get("AD")
            dp = vcf_sample.get("DP")

            alt_reads = sum(ad[1:])
            vaf = alt_reads / dp

            # Assert each VAF is >= min_alt_vaf
            assert vaf >= min_alt_vaf, f"Variant {record} has VAF {vaf} which is < min_alt_vaf ({min_alt_vaf})"
        