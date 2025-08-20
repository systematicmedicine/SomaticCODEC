"""
--- test_ms_germline_variants_mask.py

Tests the rule ms_germline_variants_mask

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
from scripts.get_metadata import load_config, get_ms_sample_ids

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