"""
--- sam_utils.py ---

Functions for obtaining data from SAM files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""

# Counts the number of reads in a SAM file
def count_sam_data_points(path):
    count = 0
    with open(path, 'r') as file:
        for line in file:
            if not line.startswith('@'):
                count += 1
    return count