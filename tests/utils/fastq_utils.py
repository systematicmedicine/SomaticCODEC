"""
--- fastq_utils.py ---

Functions for obtaining data from FASTQ files.

Authors: 
    - Chat-GPT
    - Cameron Fraser
    - Joshua Johnstone
"""
import subprocess
import gzip

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
    sum_len_str = lines[1].split()[4].replace(",", "")
    return int(sum_len_str)

# Returns the n headers (without metadata), defaults to 100 headers
def first_n_headers(fastq_path, n=100):
    headers = []
    with gzip.open(fastq_path, "rt") as f:
        for line in f:
            if line.startswith("@"):
                headers.append(line.split()[0])
                if len(headers) >= n:
                    break
    return headers