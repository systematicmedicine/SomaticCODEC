"""
--- test_ms_germline_mask.py

Tests the rule ms_germline_mask

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
import pytest
import shutil
from snakemake import snakemake
from helpers.get_metadata import load_config, get_ms_sample_ids

# Test that germline variant BEDs have the correct structure
def test_bed_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        bed_files = [Path(f"tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
                     Path(f"tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
                     Path(f"tmp/{ms_sample}/{ms_sample}_germ_all.bed")]
        
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
    indel_padding_bases = config["sci_params"]["ms_germline_mask"]["indel_padding_bases"]

    for ms_sample in ms_samples:
        pre_padding_files = [
            Path(f"tmp/{ms_sample}/{ms_sample}_germ_insertions_unpadded.bed"),
            Path(f"tmp/{ms_sample}/{ms_sample}_germ_deletions_unpadded.bed"),
        ]
        post_padding_files = [
            Path(f"tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
            Path(f"tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
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
@pytest.mark.parametrize("germ_risk_vcf, expected_bed", [
    # Low depth, no SNV (REF only)
    ("tests/data/test_ms_germline_mask/snv_ref_only/snv_ref_only.vcf",
     "tests/data/test_ms_germline_mask/snv_ref_only/snv_ref_only_expected.bed"),
     # Low depth, SNV (ALT only)
     ("tests/data/test_ms_germline_mask/snv_alt_only/snv_alt_only.vcf",
     "tests/data/test_ms_germline_mask/snv_alt_only/snv_alt_only_expected.bed"),
     # SNV, REF and ALT
     ("tests/data/test_ms_germline_mask/snv_ref_alt/snv_ref_alt.vcf",
     "tests/data/test_ms_germline_mask/snv_ref_alt/snv_ref_alt_expected.bed"),
     # Insertion only
     ("tests/data/test_ms_germline_mask/ins_only/ins_only.vcf",
     "tests/data/test_ms_germline_mask/ins_only/ins_only_expected.bed"),
     # Deletion only
     ("tests/data/test_ms_germline_mask/del_only/del_only.vcf",
     "tests/data/test_ms_germline_mask/del_only/del_only_expected.bed"),
     # Insertion and deletion
     ("tests/data/test_ms_germline_mask/ins_del/ins_del.vcf",
     "tests/data/test_ms_germline_mask/ins_del/ins_del_expected.bed"),
     # Insertion and SNV
     ("tests/data/test_ms_germline_mask/ins_snv/ins_snv.vcf",
     "tests/data/test_ms_germline_mask/ins_snv/ins_snv_expected.bed"),
     # Deletion and SNV
     ("tests/data/test_ms_germline_mask/del_snv/del_snv.vcf",
     "tests/data/test_ms_germline_mask/del_snv/del_snv_expected.bed"),
     # Multiallelic SNV
     ("tests/data/test_ms_germline_mask/snv_multi/snv_multi.vcf",
     "tests/data/test_ms_germline_mask/snv_multi/snv_multi_expected.bed"),
     # Multiallelic insertion
     ("tests/data/test_ms_germline_mask/ins_multi/ins_multi.vcf",
     "tests/data/test_ms_germline_mask/ins_multi/ins_multi_expected.bed"),
     # Multiallelic deletion
     ("tests/data/test_ms_germline_mask/del_multi/del_multi.vcf",
     "tests/data/test_ms_germline_mask/del_multi/del_multi_expected.bed")
])

def test_variant_edge_cases(lightweight_test_run, tmp_path, germ_risk_vcf, expected_bed):

    # Load config
    config = load_config(lightweight_test_run["test_config_path"])
    
    # Copy input VCF to temporary directory
    expected_vcf_path = Path(f"tmp/SEQ0001/SEQ0001_ms_germ_risk.vcf")
    copied_vcf_path = tmp_path / expected_vcf_path
    copied_vcf_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(germ_risk_vcf, copied_vcf_path)

    # Define target BED
    target_bed = f"tmp/SEQ0001/SEQ0001_ms_germ_risk.bed"

    # Define output BED
    output_bed = Path(tmp_path, target_bed)

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
        targets=[target_bed],
        cores=1,
        verbose=True,
        workdir=str(tmp_path)
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
        
