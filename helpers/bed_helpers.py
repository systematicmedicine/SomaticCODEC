"""
--- bed_helpers.py ---

Functions for obtaining data from BED files.

Authors: 
    - Joshua Johnstone
    - Cameron Fraser
"""
import pandas as pd
import gzip
from pathlib import Path

# Counts the number of data rows in a BED file
def count_bed_data_points(path):
    path = Path(path)
    open_func = open
    if str(path).endswith(".gz"):
        open_func = gzip.open
    with open_func(path, 'rt') as file:
        return sum(1 for _ in file)

# Merge intervals of individual BED files
def merge_bed_intervals(df):
    collapsed = []
    df = df.sort_values(["chrom", "start"]).reset_index(drop=True)
    current_chr, current_start, current_end = df.iloc[0]

    for _, row in df.iloc[1:].iterrows():
        chrom, start, end = row
        if chrom == current_chr and start <= current_end:
            current_end = max(current_end, end)
        else:
            collapsed.append((current_chr, current_start, current_end))
            current_chr, current_start, current_end = chrom, start, end

    collapsed.append((current_chr, current_start, current_end))
    return pd.DataFrame(collapsed, columns=["chrom", "start", "end"])

# Read BED file as DataFrame with columns: chrom, start, end (preserve sort order)
def read_bed(path):
    df = pd.read_csv(path, sep="\t", header=None, usecols=[0, 1, 2], names=["chrom", "start", "end"])
    return df.reset_index(drop=True)

# Returns the first n lines of a BED file
def print_bed_first_n_lines(path, n_lines):
    lines = []
    with open(path, "r") as f:
        for i, line in enumerate(f):
            if i >= n_lines:
                break
            lines.append(line.rstrip())
    return "\n".join(lines)