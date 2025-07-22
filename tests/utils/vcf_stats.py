"""
--- vcf_stats.py ---

Functions for obtaining VCF file statistics.

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