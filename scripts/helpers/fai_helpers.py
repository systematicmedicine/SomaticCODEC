"""
--- fai_utils.py ---

Functions for obtaining data from FAI files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import pandas as pd

# Read .fai file and return as a DataFrame with chrom, length
def read_fai(path):
    df = pd.read_csv(path, sep="\t", header=None, usecols=[0, 1], names=["chrom", "length"])
    return df