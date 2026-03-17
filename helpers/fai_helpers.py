"""
--- fai_helpers.py ---

Functions for obtaining data from FAI files.

Authors: 
    - Joshua Johnstone
"""
import pandas as pd

# Read .fai file and return as a DataFrame with chrom, length
def read_fai(path):
    df = pd.read_csv(path, sep="\t", header=None, usecols=[0, 1], names=["chrom", "length"])
    return df

# Returns a dict with [chrom][length] from FAI file
def get_chrom_lengths(fai_path):
    chrom_lengths = {}
    with open(fai_path) as f:
        for line in f:
            chrom, length = line.strip().split("\t")[:2]
            chrom_lengths[chrom] = int(length)
    return chrom_lengths

# Returns a dict with [chrom][start_index], and total genome length
def get_chrom_offsets(chrom_lengths):
    offsets = {}
    genome_length = 0
    for chrom, length in chrom_lengths.items():
        offsets[chrom] = genome_length
        genome_length += length
    return offsets, genome_length