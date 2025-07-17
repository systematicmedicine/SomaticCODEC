"""
--- helper_functions.py --

Functions that are used across multiple test scripts

Authors:
    - Cameron Fraser
    - Chat-GPT

"""

import subprocess

# Counts the number of reads in a FASTQ file
def count_reads_fastq(fastq_path):
    result = subprocess.run(
        ["seqkit", "stats", fastq_path],
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