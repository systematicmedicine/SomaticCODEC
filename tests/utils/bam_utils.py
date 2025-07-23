"""
--- bam_utils.py ---

Functions for obtaining data from BAM files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import pysam

# Counts the number of reads in a BAM file
def count_bam_data_points(path):
    path = str(path)
    try:
        result = subprocess.run(
            ["samtools", "view", "-c", "-F", "0x900", path],
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"samtools failed on {path} with error:\n{e.stderr}")
    
# Counts the number of bases with quality of 2 in a BAM file
def count_bam_q2_bases(path):
    path = str(path)
    count = 0
    with pysam.AlignmentFile(path, "rb", check_sq=False) as bam:
        for read in bam.fetch(until_eof=True):
                quals = read.query_qualities
                if quals:
                    count += sum(1 for q in quals if q == 2)
    return count
    
def count_bam_mapq_under_60(path):
    path = str(path)
    count = 0
    with pysam.AlignmentFile(path, "rb", check_sq=False) as bam:
        for read in bam.fetch(until_eof=True):
            if not read.is_unmapped and read.mapping_quality < 60:
                count += 1
    return count

def count_marked_duplicates(bam_path):
    count = 0
    with pysam.AlignmentFile(bam_path, "rb") as bam:
        for read in bam:
            if read.is_duplicate:
                count += 1
    return count

def count_reads_with_read_group(bam_path):
    reads_with_rg = 0
    with pysam.AlignmentFile(bam_path, "rb") as bam:
        for read in bam:
            if read.has_tag("RG"):
                reads_with_rg += 1
    return reads_with_rg