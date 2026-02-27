"""
--- test_combine_masks.py

Tests the rule combine_masks

Authors:
    - Chat-GPT
    - Joshua Johnstone
    - Cameron Fraser
"""

import pandas as pd
from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_ids
from helpers.bed_helpers import merge_bed_intervals, read_bed
from definitions.paths.io import ms as MS
from definitions.paths.io import shared as S
import helpers.get_metadata as md

# Helper function to assert that combined BED matches expected merge of individual beds
def assert_correctly_merged(lightweight_test_run, ms_sample):

    # Load config
    config = load_config(lightweight_test_run["test_config_path"])

    # Load individual BED files
    pre_files = [
        MS.LOW_DEPTH_MASK.format(ms_sample=ms_sample),
        *[MS.GERMLINE_RISK_MASK.format(ms_sample=ms_sample)
          for ms_sample in md.get_ms_sample_ids(config)],
        *config["sci_params"]["shared"]["precomputed_masks"],
        S.EXCLUDED_CHROMS_BED
        ]
    pre_dfs = [read_bed(f) for f in pre_files]

    # Combine into one dataframe
    combined_df = pd.concat(pre_dfs, ignore_index=True)

    # Merge BED intervals
    merged_df = merge_bed_intervals(combined_df)

    # Load actual bedtools merge output
    output_df = read_bed(Path(MS.COMBINED_MASK.format(ms_sample=ms_sample)))

    # Assert pandas merge and bedtools merge outputs match
    pd.testing.assert_frame_equal(
        output_df.sort_values(["chrom", "start"]).reset_index(drop=True),
        merged_df.sort_values(["chrom", "start"]).reset_index(drop=True),
        check_dtype=False,
        obj="Expected merge output and combined_mask.bed"
        )

# Test that combined BED matches expected merge of individual beds
def test_combined_bed_matches_individual_beds(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    for ms_sample in ms_samples:
        assert_correctly_merged(lightweight_test_run, ms_sample)

# Function to assert that the chromosome order of the combined BED matches the reference order
def assert_combined_bed_order_matches_ref(lightweight_test_run, ms_sample):
    # Load combined BED file
    bed_df = read_bed(Path(MS.COMBINED_MASK.format(ms_sample=ms_sample)))

    # Load reference fai file and get chromosome order as a list
    config = load_config(lightweight_test_run["test_config_path"])
    fai_path = config["sci_params"]["shared"]["reference_genome"] + ".fai"
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
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)
    for ms_sample in ms_samples:
        assert_combined_bed_order_matches_ref(lightweight_test_run, ms_sample)