"""
--- test_generate_include_bed --

Tests the rule generate_include_bed

This test has been tested by changing the shell script of the rule in the following way:
    - Correct shell: 
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed} 2>> {log}
    - Incorrect shell (test fails): 
        cp {input.mask_bed} {output.include_bed} 2>> {log}

Authors:
    - Chat-GPT
    - Cameron Fraser
"""

import pytest
import pandas as pd
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).resolve().parent.parent))  # adds PROJECT_ROOT to path
from scripts.get_metadata import load_config, get_ex_to_ms_sample_map


# Read BED file as sorted DataFrame with columns: chrom, start, end
def read_bed(path):
    
    df = pd.read_csv(path, sep="\t", header=None, usecols=[0, 1, 2], names=["chrom", "start", "end"])
    return df.sort_values(["chrom", "start"]).reset_index(drop=True)


# Read .fai file and return as a DataFrame with chrom, length
def read_fai(path):
    
    df = pd.read_csv(path, sep="\t", header=None, usecols=[0, 1], names=["chrom", "length"])
    return df


# Assert that the union of mask and include BED intervals exactly covers the reference genome
def merge_and_check_coverage(mask_df, include_df, fai_df):
    genome_intervals = []
    for _, row in fai_df.iterrows():
        genome_intervals.append((row["chrom"], 0, row["length"]))
    genome_df = pd.DataFrame(genome_intervals, columns=["chrom", "start", "end"])

    # Concatenate and sort
    combined = pd.concat([mask_df, include_df]).sort_values(["chrom", "start"]).reset_index(drop=True)

    # Check for overlapping intervals
    overlaps = (
        (combined["start"].shift(-1) < combined["end"]) &
        (combined["chrom"].shift(-1) == combined["chrom"])
    )
    assert not overlaps.any(), "Mask + include BEDs contain overlapping intervals"

    # Collapse combined intervals
    collapsed = []
    current_chr, current_start, current_end = combined.iloc[0]

    for _, row in combined.iloc[1:].iterrows():
        chrom, start, end = row
        if chrom == current_chr and start <= current_end:
            current_end = max(current_end, end)
        else:
            collapsed.append((current_chr, current_start, current_end))
            current_chr, current_start, current_end = chrom, start, end

    collapsed.append((current_chr, current_start, current_end))
    collapsed_df = pd.DataFrame(collapsed, columns=["chrom", "start", "end"])

    # Now check that the collapsed set equals the full genome regions
    pd.testing.assert_frame_equal(collapsed_df.reset_index(drop=True), genome_df.reset_index(drop=True),
                                  check_dtype=False, obj="Collapsed union of mask + include")


# Test that the BED files do not overlap, and overlaps the entire reference genome
def test_include_bed_complement_and_coverage(lightweight_test_run):
    # Load config and metadata
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ex_to_ms = get_ex_to_ms_sample_map(config)
    fai_path = config["GRCh38_path"] + ".fai"
    fai_df = read_fai(fai_path)

    for ex_sample, ms_sample in ex_to_ms.items():
        mask_path = Path(f"tmp/{ms_sample}/{ms_sample}_combined_mask.bed")
        include_path = Path(f"tmp/{ex_sample}/{ex_sample}_include.bed")

        assert mask_path.exists(), f"Missing input mask BED: {mask_path}"
        assert include_path.exists(), f"Missing output include BED: {include_path}"

        mask_df = read_bed(mask_path)
        include_df = read_bed(include_path)

        # Test 1: No overlap between mask and include
        combined = pd.concat([mask_df.assign(set="mask"), include_df.assign(set="include")])
        combined = combined.sort_values(["chrom", "start"]).reset_index(drop=True)

        overlap_found = (
            (combined["start"].shift(-1) < combined["end"]) &
            (combined["chrom"].shift(-1) == combined["chrom"]) &
            (combined["set"] != combined["set"].shift(-1))
        ).any()
        assert not overlap_found, f"Overlap found between mask and include for {ex_sample}"

        # Test 2: Together they fully cover the genome
        merge_and_check_coverage(mask_df, include_df, fai_df)
