"""
--- test_ms_germline_mask.py

Tests the rule ms_germline_mask

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
from helpers.get_metadata import load_config, get_ms_sample_ids

# Test that germline variant BEDs have the correct structure
def test_bed_structure_correct(lightweight_test_run):
    config = load_config("config/config.yaml")
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        bed_files = [Path(f"tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
                     Path(f"tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
                     Path(f"tmp/{ms_sample}/{ms_sample}_germ_snvs.bed")]
        
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

def test_indel_padding_added(lightweight_test_run):
    def read_bed(path):
        return (
            pd.read_csv(path, sep="\t", header=None, usecols=[0,1,2],
                        names=["chrom","start","end"])
            .sort_values(["chrom","start"])
            .reset_index(drop=True))

    config = load_config("config/config.yaml")
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
