"""
--- sam_helpers.py ---

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

# Returns the first n lines of a SAM file
def print_sam_first_n_lines(path, n_lines):
    lines = []
    with open(path, "r") as f:
        for i, line in enumerate(f):
            if i >= n_lines:
                break
            lines.append(line.rstrip())
    return "\n".join(lines)