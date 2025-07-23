"""
--- test_ms_candidate_germ_variants.py

Tests the rule ms_candidate_germ_variants

Authors:
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import pandas as pd
import gzip

# Test that VCF has the correct structure
def test_vcf_structure_correct(lightweight_test_run):
    ms_samples = pd.read_csv("tests/configs/lightweight_test_run/ms_samples.csv")["ms_sample"].to_list()

    for ms_sample in ms_samples:
        vcf_file = Path(f"tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")

        with gzip.open(vcf_file, 'rt') as f:
            for linenum, line in enumerate(f, start=1):
                line = line.rstrip('\n')

                # Skip meta-information lines
                if line.startswith('##'):
                    continue  
                
                # Check header
                if line.startswith('#'):
                    header_cols = line.lstrip('#').split('\t')

                    # Assertion 1: Header has at least 8 tab-separated columns
                    assert len(header_cols) >= 8, f"VCF header on line {linenum} has fewer than 8 columns: {line}"
                    continue
                
                # Check data lines
                data_cols =  line.split('\t')

                # Assertion 2: Data lines have at least 8 tab-separated columns
                assert len(data_cols) >= 8, f"Line {linenum} has fewer than 8 columns: {line}"

                # Check data fields
                pos = data_cols[1]
                ref = data_cols[3]
                alt = data_cols[4]

                # Assertion 3: Position (POS) is a positive integer
                assert pos.isdigit() and int(pos) > 0, f"Invalid POS on line {linenum}: {pos}"

                # Assertion 4: REF and ALT alleles are present
                assert ref != '', f"Empty REF on line {linenum}: {line}"
                assert alt != '', f"Empty ALT on line {linenum}: {line}"