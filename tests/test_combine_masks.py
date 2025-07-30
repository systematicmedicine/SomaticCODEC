"""
--- test_combine_masks.py

Tests the rule combine_masks

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""

import pandas as pd
from pathlib import Path
from test_generate_include_bed import read_bed
from scripts.get_metadata import load_config, get_ms_sample_ids
from utils.bed_utils import merge_bed_intervals

# Assert that combined BED matches expected merge of individual beds
def assert_correctly_merged(ms_sample):
    # Load individual BED files
    pre_files = [
        Path(f"tmp/{ms_sample}/{ms_sample}_lowdepth.bed"),
        Path(f"tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
        Path(f"tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
        Path(f"tmp/{ms_sample}/{ms_sample}_germ_snvs.bed"),
        Path("tmp/downloads/GRCh38_alldifficultregions_10lines.bed"),
        Path("tmp/downloads/gnomad_common_af01_merged_10lines.bed")
        ]
    pre_dfs = [read_bed(f) for f in pre_files]

    # Combine into one dataframe
    combined_df = pd.concat(pre_dfs, ignore_index=True)

    # Merge BED intervals
    merged_df = merge_bed_intervals(combined_df)

    # Load actual bedtools merge output
    output_df = read_bed(Path(f"tmp/{ms_sample}/{ms_sample}_combined_mask.bed"))

    # Assert pandas merge and bedtools merge outputs match
    pd.testing.assert_frame_equal(
        output_df.sort_values(["chrom", "start"]).reset_index(drop=True),
        merged_df.sort_values(["chrom", "start"]).reset_index(drop=True),
        check_dtype=False,
        obj="Expected merge output and combined_mask.bed"
        )

# Test that combined BED matches expected merge of individual beds
def test_combined_bed_matches_individual_beds(lightweight_test_run):
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ms_samples = get_ms_sample_ids(config)
    for ms_sample in ms_samples:
        assert_correctly_merged(ms_sample)

# Assert that the chromosome order of the combined BED matches the reference order
def assert_combined_bed_order_matches_ref(ms_sample):
    # Load combined BED file
    bed_df = read_bed(Path(f"tmp/{ms_sample}/{ms_sample}_combined_mask.bed"))

    # Load reference fai file and get chromosome order as a list
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    fai_path = config["GRCh38_path"] + ".fai"
    fai_df = pd.read_csv(fai_path, sep="\t", header=None, usecols=[0], names=["chrom"])
    fai_chrom_order = fai_df["chrom"].tolist()

    # Extract unique chromosomes from BED in order of first appearance
    bed_chroms = list(dict.fromkeys(bed_df["chrom"]))

    expected_order = [chrom for chrom in fai_chrom_order if chrom in bed_chroms]

    assert bed_chroms == expected_order, (
        f"Chromosomes in combined_mask.bed for {ms_sample} are not in correct numeric order.\n"
        f"Found: {bed_chroms}\nExpected: {expected_order}"
        )

# Test that the chromosome order of the combined BED matches the reference order
def test_combined_bed_order_matches_ref(lightweight_test_run):
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ms_samples = get_ms_sample_ids(config)
    for ms_sample in ms_samples:
        assert_combined_bed_order_matches_ref(ms_sample)