"""
--- fasta_stats.py ---

Functions for obtaining FASTA file statistics.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
from pathlib import Path
import gzip

# Counts the number of sequences in a FASTA file
def count_fasta_data_points(path):
    path = Path(path)
    open_func = open
    if str(path).endswith(".gz"):
        open_func = gzip.open
    count = 0
    with open_func(path, 'rt') as file:
        for line in file:
            if line.startswith('>'):
                count += 1
    return count