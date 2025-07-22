"""
--- tabular_stats.py ---

Functions for obtaining tabular (.csv, .tsv, .txt) file statistics.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""

# Counts the number of data rows in a tabular file
def count_tabular_data_points(path):
    count = 0
    with open(path) as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith("#"):
                count += 1
    return count