"""
--- bcf_helpers.py ---

Functions for obtaining data from BCF files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import pysam

# Counts the number of variant records in a BCF file
def count_bcf_data_points(path):
    count = 0
    with pysam.VariantFile(path, "rb") as file:
        for _ in file.fetch():
            count += 1
    return count

# Returns the first n lines of a BCF file
def print_bcf_first_n_lines(path, n_lines):
    lines = []
    with pysam.VariantFile(path, "rb") as bcf:
        for i, rec in enumerate(bcf):
            if i >= n_lines:
                break
            lines.append(str(rec).rstrip())
    return "\n".join(lines)