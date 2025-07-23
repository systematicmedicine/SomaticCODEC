"""
--- bcf_utils.py ---

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