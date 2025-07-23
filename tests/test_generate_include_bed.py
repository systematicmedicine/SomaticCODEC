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
from utils.bed_utils import read_bed
from utils.fai_utils import read_fai

# Add PROJECT_ROOT to sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent))

from scripts.get_metadata import load_config, get_ex_to_ms_sample_map

# Load input and output BEDs for a sample
def get_mask_and_include_beds(ex_sample, ms_sample):
    mask_path = Path(f"tmp/{ms_sample}/{ms_sample}_combined_mask.bed")
    include_path = Path(f"tmp/{ex_sample}/{ex_sample}_include.bed")

    assert mask_path.exists(), f"Missing input mask BED: {mask_path}"
    assert include_path.exists(), f"Missing output include BED: {include_path}"

    return read_bed(mask_path), read_bed(include_path)


# Assert that the mask and include regions are disjoint
def assert_no_overlap(mask_df, include_df, ex_sample):
    combined = pd.concat([mask_df.assign(set="mask"), include_df.assign(set="include")])
    combined = combined.sort_values(["chrom", "start"]).reset_index(drop=True)

    overlap_found = (
        (combined["start"].shift(-1) < combined["end"]) &
        (combined["chrom"].shift(-1) == combined["chrom"]) &
        (combined["set"] != combined["set"].shift(-1))
    ).any()
    assert not overlap_found, f"Overlap found between mask and include for {ex_sample}"


# Assert that the union of mask and include exactly spans the genome
def assert_spans_reference(mask_df, include_df, fai_df):
    genome_df = fai_df.copy()
    genome_df["start"] = 0
    genome_df["end"] = genome_df["length"]
    genome_df = genome_df[["chrom", "start", "end"]]

    chrom_order = list(genome_df["chrom"].unique())
    combined = (pd.concat([mask_df, include_df])
                .assign(chrom=lambda d: pd.Categorical(d["chrom"], categories=chrom_order, ordered=True))
                .sort_values(["chrom", "start"])
                .reset_index(drop=True))

    # Collapse adjacent/overlapping intervals
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

    pd.testing.assert_frame_equal(collapsed_df.reset_index(drop=True), genome_df.reset_index(drop=True),
                                  check_dtype=False, obj="Collapsed union of mask + include")


# Test that the input (mask) and output (include) BEDs do not overlap
def test_beds_dont_overlap(lightweight_test_run):
    
    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ex_to_ms = get_ex_to_ms_sample_map(config)

    for ex_sample, ms_sample in ex_to_ms.items():
        mask_df, include_df = get_mask_and_include_beds(ex_sample, ms_sample)
        assert_no_overlap(mask_df, include_df, ex_sample)

# Test that mask + include BEDs span the entire reference
def test_beds_span_reference(lightweight_test_run):

    config = load_config("tests/configs/lightweight_test_run/config.yaml")
    ex_to_ms = get_ex_to_ms_sample_map(config)
    fai_path = config["GRCh38_path"] + ".fai"
    fai_df = read_fai(fai_path)

    for ex_sample, ms_sample in ex_to_ms.items():
        mask_df, include_df = get_mask_and_include_beds(ex_sample, ms_sample)
        assert_spans_reference(mask_df, include_df, fai_df)
