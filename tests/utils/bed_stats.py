"""
--- bed_stats.py ---

Functions for obtaining BED file statistics.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""

# Counts the number of data rows in a BED file
def count_bed_data_points(path):
    with open(path, 'r') as file:
        return sum(1 for _ in file)