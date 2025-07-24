"""
--- vcf_utils.py ---

Functions for obtaining data from VCF files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import gzip

# Counts the number of data rows in a VCF file
def count_vcf_data_points(path):
    path = Path(path)
    open_func = gzip.open if "".join(path.suffixes[-2:]) == ".vcf.gz" else open
    count = 0
    with open_func(path, 'rt') as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith("#"):
                count += 1
    return count

def check_vcf_structure(path):
    path = Path(path)
    open_func = gzip.open if path.suffix == '.gz' else open

    with open_func(path, 'rt') as f:
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
                
                # Get data lines
                data_cols =  line.split('\t')

                # Assertion 2: Data lines have at least 8 tab-separated columns
                assert len(data_cols) >= 8, f"Line {linenum} has fewer than 8 columns: {line}"

                # Get data fields
                pos = data_cols[1]
                ref = data_cols[3]
                alt = data_cols[4]

                # Assertion 3: Position (POS) is a positive integer
                assert pos.isdigit() and int(pos) > 0, f"Invalid POS on line {linenum}: {pos}"

                # Assertion 4: REF and ALT alleles are present
                assert ref != '', f"Empty REF on line {linenum}: {line}"
                assert alt != '', f"Empty ALT on line {linenum}: {line}"