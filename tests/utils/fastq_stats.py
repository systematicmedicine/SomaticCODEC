"""
--- fastq_stats.py ---

Functions for obtaining FASTQ file statistics.

Authors: 
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""
import subprocess
# Counts the number of reads in a FASTQ file
def count_fastq_data_points(path):
    result = subprocess.run(
        ["seqkit", "stats", path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True
    )
    lines = result.stdout.strip().split('\n')
    read_count_str = lines[1].split()[3].replace(",", "")
    return int(read_count_str)

# Returns the sum of the length of all reads in a FASTQ file 
def sum_len_fastq(fastq_path):
    result = subprocess.run(
        ["seqkit", "stats", fastq_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=True
    )
    lines = result.stdout.strip().split('\n')
    sum_len_str = lines[1].split()[5].replace(",", "")
    return int(sum_len_str)