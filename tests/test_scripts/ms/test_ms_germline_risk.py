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
import pytest
import shutil
from snakemake import snakemake
from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.vcf_helpers import check_vcf_structure

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
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

# Test that allele depth edge cases are correctly included in germ risk VCF     
@pytest.mark.parametrize("deduped_bam, deduped_bai, expected_vcf, unexpected_vcf", [
    # Depth < 40, ALT VAF >= 0.10
    ("tests/data/test_ms_germline_risk/AD_0_1/deduped_map_AD_0_1.bam", 
     "tests/data/test_ms_germline_risk/AD_0_1/deduped_map_AD_0_1.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_0_1/expected_AD_0_1.vcf",
     "tests/data/test_ms_germline_risk/AD_0_1/unexpected_AD_0_1.vcf"),
     # Depth < 40, ALT VAF < 0.10
     ("tests/data/test_ms_germline_risk/AD_1_0/deduped_map_AD_1_0.bam", 
     "tests/data/test_ms_germline_risk/AD_1_0/deduped_map_AD_1_0.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_1_0/expected_AD_1_0.vcf",
     "tests/data/test_ms_germline_risk/AD_1_0/unexpected_AD_1_0.vcf"),
     # Depth >= 40, ALT VAF >= 0.10
     ("tests/data/test_ms_germline_risk/AD_36_4/deduped_map_AD_36_4.bam", 
     "tests/data/test_ms_germline_risk/AD_36_4/deduped_map_AD_36_4.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_36_4/expected_AD_36_4.vcf",
     "tests/data/test_ms_germline_risk/AD_36_4/unexpected_AD_36_4.vcf"),
     # Depth >= 40, ALT VAF < 0.10
     ("tests/data/test_ms_germline_risk/AD_37_3/deduped_map_AD_37_3.bam", 
     "tests/data/test_ms_germline_risk/AD_37_3/deduped_map_AD_37_3.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_37_3/expected_AD_37_3.vcf",
     "tests/data/test_ms_germline_risk/AD_37_3/unexpected_AD_37_3.vcf"),
     # Depth >=40, summed ALT VAF >= 0.10
     ("tests/data/test_ms_germline_risk/AD_36_2_2/deduped_map_AD_36_2_2.bam", 
     "tests/data/test_ms_germline_risk/AD_36_2_2/deduped_map_AD_36_2_2.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_36_2_2/expected_AD_36_2_2.vcf",
     "tests/data/test_ms_germline_risk/AD_36_2_2/unexpected_AD_36_2_2.vcf"),
     # Depth >=40, summed ALT VAF < 0.10
     ("tests/data/test_ms_germline_risk/AD_37_2_1/deduped_map_AD_37_2_1.bam", 
     "tests/data/test_ms_germline_risk/AD_37_2_1/deduped_map_AD_37_2_1.bam.bai", 
     "tests/data/test_ms_germline_risk/AD_37_2_1/expected_AD_37_2_1.vcf",
     "tests/data/test_ms_germline_risk/AD_37_2_1/unexpected_AD_37_2_1.vcf")
])
def test_variant_edge_cases(lightweight_test_run, tmp_path, deduped_bam, deduped_bai, expected_vcf, unexpected_vcf):

    # Returns a dict with CHROM, POS, REF, ALT, AD fields
    def parse_vcf_line(line):
        fields = line.strip().split('\t')
        chrom = fields[0]
        pos = fields[1]
        ref = fields[3]
        alt = fields[4]

        format_fields = fields[8].split(':')
        sample_fields = fields[9].split(':')
        ad_index = format_fields.index("AD")
        ad_value = sample_fields[ad_index]

        return {"CHROM": chrom, "POS": pos, "REF": ref, "ALT": alt, "AD": ad_value}
    
    # Load config
    config = load_config(lightweight_test_run["test_config_path"])

    # Set MS depth threshold higher to allow for testing of depth filter
    config["sci_params"]["ms_low_depth_mask"]["min_depth"] = 40

    # Copy input BAM and BAI to temporary directory
    expected_bam_path = Path(f"tmp/SEQ0001/SEQ0001_deduped_map.bam")
    expected_bai_path = Path(f"tmp/SEQ0001/SEQ0001_deduped_map.bam.bai")

    copied_bam_path = tmp_path / expected_bam_path
    copied_bai_path = tmp_path / expected_bai_path

    copied_bam_path.parent.mkdir(parents=True, exist_ok=True)
    copied_bai_path.parent.mkdir(parents=True, exist_ok=True)

    shutil.copy(deduped_bam, copied_bam_path)
    shutil.copy(deduped_bai, copied_bai_path)

    # Define target VCF
    target_vcf = f"tmp/SEQ0001/SEQ0001_ms_germ_risk.vcf"

    # Define output VCF
    output_vcf = Path(tmp_path, target_vcf)

    # Copy snakemake files to temporary directory
    shutil.copy("Snakefile", tmp_path / "Snakefile")
    shutil.copytree("scripts", tmp_path / "scripts")
    shutil.copytree("rules", tmp_path / "rules")
    shutil.copytree("tmp/downloads", tmp_path / "tmp/downloads")
    shutil.copytree("tests/data/lightweight_test_run/config", tmp_path / "tests/data/lightweight_test_run/config")
    shutil.copytree("definitions", tmp_path / "definitions")

    # Run snakemake inside temporary directory
    success = snakemake(
        snakefile=str(tmp_path / "Snakefile"),
        config=config,
        targets=[target_vcf],
        cores=1,
        verbose=True,
        workdir=str(tmp_path),
        allowed_rules=["ms_germline_risk"]
        )

    # Assert that rule succeeded
    assert success

    # Assert that output VCF matches expected VCF
    with open(output_vcf) as vcf_out, open(expected_vcf) as vcp_exp, open(unexpected_vcf) as vcf_unexp:
        output_variants = [parse_vcf_line(line) for line in vcf_out if not line.startswith("#")]
        expected_variants = [parse_vcf_line(line) for line in vcp_exp if not line.startswith("#")]
        unexpected_variants = [parse_vcf_line(line) for line in vcf_unexp if not line.startswith("#")]

    missing_variants = [
    expected_variant for expected_variant in expected_variants
    if expected_variant not in output_variants
    ]

    present_unexpected_variants = [
        unexpected_variant for unexpected_variant in unexpected_variants
        if unexpected_variant in output_variants
    ]

    assert not present_unexpected_variants, (f"Unexpected variants found: {present_unexpected_variants}",
                                             f"Output VCF variants: {output_variants}")

    assert not missing_variants, (f"Expected variants not found in output VCF: {missing_variants}",
                                  f"Output VCF variants: {output_variants}")
