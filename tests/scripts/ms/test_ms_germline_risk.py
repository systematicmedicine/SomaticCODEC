"""
--- test_ms_germline_risk.py

Tests the rule ms_germline_risk

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""

# Import libraries
from pathlib import Path
import pysam
import pytest
import shutil
import pandas as pd
from snakemake import snakemake
from helpers.get_metadata import load_config, get_ms_sample_ids
from definitions.paths.io import ms as MS

# Test that all variants in MS pileup depth alt have alt VAF >= min_alt_vaf
def test_alt_vaf_filter(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    min_alt_vaf = config["sci_params"]["ms_germline_risk"]["min_alt_vaf"]

    for ms_sample in ms_samples:
        # Locate VCF file
        vcf_file_path = Path(MS.GERMLINE_RISK_INT1.format(ms_sample=ms_sample))

        # Open VCF with pysam
        vcf_file = pysam.VariantFile(vcf_file_path)

        # Get alt VAF and depth for each variant
        for record in vcf_file:
            vcf_sample = next(iter(record.samples.values()))
            ad = vcf_sample.get("AD")
            dp = vcf_sample.get("DP")

            alt_reads = sum(ad[1:])
            alt_vaf = alt_reads / dp if dp > 0 else 0

            # Assert variants fit criteria
            assert alt_vaf >= min_alt_vaf, (
                f"Variant {record} has alt VAF ({alt_vaf}) < min_alt_vaf ({min_alt_vaf})"
                )

# Test that allele depth edge cases are correctly included/discluded by the alt VAF filter
# Assumes that min_alt_vaf is set to 0.10 
@pytest.mark.parametrize("pileup_depth_vcf, expected_vcf, unexpected_vcf", [
    # REF only (alt VAF = 0)
    ("tests/data/test_ms_germline_risk/AD_40_0/pileup_depth_AD_40_0.vcf",
    "tests/data/test_ms_germline_risk/AD_40_0/expected_AD_40_0.vcf",
    "tests/data/test_ms_germline_risk/AD_40_0/unexpected_AD_40_0.vcf"),
    # ALT only (alt VAF = 1)
    ("tests/data/test_ms_germline_risk/AD_0_40/pileup_depth_AD_0_40.vcf", 
     "tests/data/test_ms_germline_risk/AD_0_40/expected_AD_0_40.vcf",
     "tests/data/test_ms_germline_risk/AD_0_40/unexpected_AD_0_40.vcf"),
    # REF and ALT (alt VAF = 0.1)
    ("tests/data/test_ms_germline_risk/AD_36_4/pileup_depth_AD_36_4.vcf",
    "tests/data/test_ms_germline_risk/AD_36_4/expected_AD_36_4.vcf",
    "tests/data/test_ms_germline_risk/AD_36_4/unexpected_AD_36_4.vcf"),
    # REF and ALT (alt VAF = 0.075)
    ("tests/data/test_ms_germline_risk/AD_37_3/pileup_depth_AD_37_3.vcf",
    "tests/data/test_ms_germline_risk/AD_37_3/expected_AD_37_3.vcf",
    "tests/data/test_ms_germline_risk/AD_37_3/unexpected_AD_37_3.vcf"),
    # Multiple ALTs (alt VAF = 0.10)
    ("tests/data/test_ms_germline_risk/AD_36_2_2/pileup_depth_AD_36_2_2.vcf", 
    "tests/data/test_ms_germline_risk/AD_36_2_2/expected_AD_36_2_2.vcf",
    "tests/data/test_ms_germline_risk/AD_36_2_2/unexpected_AD_36_2_2.vcf"),
    # Multiple ALTs (alt VAF = 0.075)
    ("tests/data/test_ms_germline_risk/AD_37_2_1/pileup_depth_AD_37_2_1.vcf",
    "tests/data/test_ms_germline_risk/AD_37_2_1/expected_AD_37_2_1.vcf",
    "tests/data/test_ms_germline_risk/AD_37_2_1/unexpected_AD_37_2_1.vcf")
])
def test_variant_edge_cases_vcf(lightweight_test_run, tmp_path, pileup_depth_vcf, expected_vcf, unexpected_vcf):

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

    # Define test sample ID
    ms_sample = "SEQ0001"

    # Set MS depth threshold higher to allow for testing of depth filter
    config["sci_params"]["ms_pileup"]["min_depth"] = 40

    # Copy input pileup depth VCF temporary directory
    expected_pileup_depth_path = Path(MS.PILEUP_DEPTH.format(ms_sample=ms_sample))
    copied_pileup_depth_path = tmp_path / expected_pileup_depth_path
    copied_pileup_depth_path.parent.mkdir(parents=True, exist_ok=True)

    shutil.copy(pileup_depth_vcf, copied_pileup_depth_path)

    # Define target VCF
    target_vcf = MS.GERMLINE_RISK_INT1.format(ms_sample=ms_sample)

    # Define output VCF
    output_vcf = Path(tmp_path, target_vcf)

    # Copy snakemake files to temporary directory
    shutil.copy("Snakefile", tmp_path / "Snakefile")
    shutil.copytree("rule_scripts", tmp_path / "rule_scripts")
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


# Test that germline variant BEDs have the correct structure
def test_bed_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        bed_files = [Path(MS.GERMLINE_RISK_INT7.format(ms_sample=ms_sample)),
                     Path(MS.GERMLINE_RISK_INT8.format(ms_sample=ms_sample)),
                     Path(MS.GERMLINE_RISK_INT9.format(ms_sample=ms_sample))]
        
        for bed_file in bed_files:
            with bed_file.open() as f:
                for linenum, line in enumerate(f, start=1):
                    cols = line.rstrip('\n').split('\t')

                    # Assertion 1: File has 3 tab-separated columns
                    assert len(cols) == 3, f"Line {linenum} does not have 3 columns: {line}"
                    start = int(cols[1])
                    end = int(cols[2])

                    # Assertion 2: Start position is before end position
                    assert start < end, f"Start >= end on line {linenum}: {line}"

# Test that padding has been added either side of INDELs
def test_indel_padding_added(lightweight_test_run):
    def read_bed(path):
        return (
            pd.read_csv(path, sep="\t", header=None, usecols=[0,1,2],
                        names=["chrom","start","end"])
            .sort_values(["chrom","start"])
            .reset_index(drop=True))

    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    indel_padding_bases = config["sci_params"]["ms_germline_risk"]["indel_padding_bases"]

    for ms_sample in ms_samples:
        pre_padding_files = [
            Path(MS.GERMLINE_RISK_INT5.format(ms_sample=ms_sample)),
            Path(MS.GERMLINE_RISK_INT6.format(ms_sample=ms_sample)),
        ]
        post_padding_files = [
            Path(MS.GERMLINE_RISK_INT7.format(ms_sample=ms_sample)),
            Path(MS.GERMLINE_RISK_INT8.format(ms_sample=ms_sample)),
        ]

        for pre_path, post_path in zip(pre_padding_files, post_padding_files):
            pre_df = read_bed(pre_path)
            post_df = read_bed(post_path)

            # Calculate expected padded start/end positions
            expected_start = (pre_df["start"] - indel_padding_bases).clip(lower=0)
            expected_end   = pre_df["end"] + indel_padding_bases

            # assert both start and end match expected
            assert (post_df["start"].values == expected_start.values).all(), \
                f"Starts not padded/clamped correctly in {post_path}"
            assert (post_df["end"].values == expected_end.values).all(), \
                f"Ends not padded correctly in {post_path}"     

# Test that variant edge cases are correctly included in germ risk BED  
@pytest.mark.parametrize("pileup_depth_vcf, expected_bed", [
    # No SNV, REF only
    ("tests/data/test_ms_germline_risk/snv_ref_only/snv_ref_only.vcf",
     "tests/data/test_ms_germline_risk/snv_ref_only/snv_ref_only_expected.bed"),
     # SNV, ALT only
     ("tests/data/test_ms_germline_risk/snv_alt_only/snv_alt_only.vcf",
     "tests/data/test_ms_germline_risk/snv_alt_only/snv_alt_only_expected.bed"),
     # SNV, REF and ALT
     ("tests/data/test_ms_germline_risk/snv_ref_alt/snv_ref_alt.vcf",
     "tests/data/test_ms_germline_risk/snv_ref_alt/snv_ref_alt_expected.bed"),
     # Insertion only
     ("tests/data/test_ms_germline_risk/ins_only/ins_only.vcf",
     "tests/data/test_ms_germline_risk/ins_only/ins_only_expected.bed"),
     # Deletion only
     ("tests/data/test_ms_germline_risk/del_only/del_only.vcf",
     "tests/data/test_ms_germline_risk/del_only/del_only_expected.bed"),
     # Insertion and deletion
     ("tests/data/test_ms_germline_risk/ins_del/ins_del.vcf",
     "tests/data/test_ms_germline_risk/ins_del/ins_del_expected.bed"),
     # Insertion and SNV
     ("tests/data/test_ms_germline_risk/ins_snv/ins_snv.vcf",
     "tests/data/test_ms_germline_risk/ins_snv/ins_snv_expected.bed"),
     # Deletion and SNV
     ("tests/data/test_ms_germline_risk/del_snv/del_snv.vcf",
     "tests/data/test_ms_germline_risk/del_snv/del_snv_expected.bed"),
     # Multiallelic SNV
     ("tests/data/test_ms_germline_risk/snv_multi/snv_multi.vcf",
     "tests/data/test_ms_germline_risk/snv_multi/snv_multi_expected.bed"),
     # Multiallelic insertion
     ("tests/data/test_ms_germline_risk/ins_multi/ins_multi.vcf",
     "tests/data/test_ms_germline_risk/ins_multi/ins_multi_expected.bed"),
     # Multiallelic deletion
     ("tests/data/test_ms_germline_risk/del_multi/del_multi.vcf",
     "tests/data/test_ms_germline_risk/del_multi/del_multi_expected.bed")
])

def test_variant_edge_cases_bed(lightweight_test_run, tmp_path, pileup_depth_vcf, expected_bed):

    # Load config
    config = load_config(lightweight_test_run["test_config_path"])

    # Define test ms_sample ID
    ms_sample = "SEQ0001"
    
    # Copy input VCF to temporary directory
    expected_vcf_path = Path(MS.PILEUP_DEPTH.format(ms_sample=ms_sample))
    copied_vcf_path = tmp_path / expected_vcf_path
    copied_vcf_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(pileup_depth_vcf, copied_vcf_path)

    # Define target BED
    target_bed = MS.GERMLINE_RISK_MASK.format(ms_sample=ms_sample)

    # Define output BED
    output_bed = Path(tmp_path, target_bed)

    # Copy snakemake files to temporary directory
    shutil.copy("Snakefile", tmp_path / "Snakefile")
    shutil.copytree("rule_scripts", tmp_path / "rule_scripts")
    shutil.copytree("rules", tmp_path / "rules")
    shutil.copytree("tmp/downloads", tmp_path / "tmp/downloads")
    shutil.copytree("tests/data/lightweight_test_run/config", tmp_path / "tests/data/lightweight_test_run/config")
    shutil.copytree("definitions", tmp_path / "definitions")

    # Run snakemake inside temporary directory
    success = snakemake(
        snakefile=str(tmp_path / "Snakefile"),
        config=config,
        targets=[target_bed],
        cores=1,
        verbose=True,
        workdir=str(tmp_path),
        allowed_rules=["ms_germline_risk"]
        )

    # Assert that rule succeeded
    assert success

    # Assert that output BED matches expected BED
    with open(output_bed) as out_bed, open(expected_bed) as exp_bed:
        output_lines = out_bed.readlines()
        expected_lines = exp_bed.readlines()

    assert output_lines == expected_lines, ("Output BED does not match expected BED",
                                            f"Output BED lines: {output_lines}",
                                            f"Expected BED lines: {expected_lines}")
