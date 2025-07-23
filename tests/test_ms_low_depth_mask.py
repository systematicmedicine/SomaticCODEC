"""
--- test_ms_low_depth_mask.py

Tests the rule ms_low_depth_mask

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd

# Test that low depth BED has the correct structure
def test_bed_structure_correct(lightweight_test_run):
    ms_samples = pd.read_csv("tests/configs/lightweight_test_run/ms_samples.csv")["ms_sample"].to_list()

    for ms_sample in ms_samples:
        bed_file = Path(f"tmp/{ms_sample}/{ms_sample}_lowdepth.bed")

        with bed_file.open() as f:
            for linenum, line in enumerate(f, start=1):
                cols = line.rstrip('\n').split('\t')

                # Assertion 1: File has 3 tab-separated columns
                assert len(cols) == 3, f"Line {linenum} does not have 3 columns: {line}"
                start = int(cols[1])
                end = int(cols[2])

                # Assertion 2: Start position is before end position
                assert start < end, f"Start >= end on line {linenum}: {line}"    