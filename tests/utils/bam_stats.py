"""
--- bam_stats.py ---

Functions for obtaining BAM file statistics.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess

# Counts the number of reads in a BAM file
def count_bam_data_points(path):
    path = str(path)
    try:
        result = subprocess.run(
            ["samtools", "view", "-c", path],
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"samtools failed on {path} with error:\n{e.stderr}")