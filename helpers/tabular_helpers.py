"""
--- tabular_helpers.py ---

Functions for obtaining data from tabular (.csv, .tsv, .txt) files.

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

# Prints the first n lines of a tabular file
def print_tabular_first_n_lines(path, n_lines):
    lines = []
    with open(path, "r") as f:
        for i, line in enumerate(f):
            if i >= n_lines:
                break
            lines.append(line.rstrip())
    return "\n".join(lines)