"""
--- test_ms_low_depth.py

Tests the rule ms_low_depth

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from helpers.get_metadata import load_config, get_ms_sample_ids
from definitions.paths.io import ms as MS

# Test that low depth BED has the correct structure
def test_bed_structure_correct(lightweight_test_run):
    config = load_config(lightweight_test_run["test_config_path"])
    ms_samples = get_ms_sample_ids(config)

    for ms_sample in ms_samples:
        bed_file = Path(MS.LOW_DEPTH_MASK.format(ms_sample=ms_sample))

        with bed_file.open() as f:
            for linenum, line in enumerate(f, start=1):
                cols = line.rstrip('\n').split('\t')

                # Assertion 1: File has 3 tab-separated columns
                assert len(cols) == 3, f"Line {linenum} does not have 3 columns: {line}"
                start = int(cols[1])
                end = int(cols[2])

                # Assertion 2: Start position is before end position
                assert start < end, f"Start >= end on line {linenum}: {line}"
