"""
--- bam_helpers.py ---

Functions for obtaining data from BAM files.

Authors: 
    - Chat-GPT
    - Joshua Johnstone
"""
import subprocess
import pysam
from helpers.get_metadata import load_config
from helpers.fai_helpers import get_chrom_offsets
import numpy as np

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
    
# Counts the number of bases with quality designated to single-stranded bases in a BAM file
def count_bam_ss_qual_bases(path):
    path = str(path)
    count = 0
    config = load_config("config/config.yaml")
    ss_qual = config["sci_params"]["ex_call_dsc"]["single_strand_qual"]
    with pysam.AlignmentFile(path, "rb", check_sq=False) as bam:
        for read in bam.fetch(until_eof=True):
                quals = read.query_qualities
                if quals:
                    count += sum(1 for q in quals if q == ss_qual)
    return count

# Count the number of reads with MPAQ under the threshold set in config
def count_bam_reads_under_min_mapq(path):
    path = str(path)
    count = 0
    config = load_config("config/config.yaml")
    min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"]
    with pysam.AlignmentFile(path, "rb", check_sq=False) as bam:
        for read in bam.fetch(until_eof=True):
            if not read.is_unmapped and read.mapping_quality < min_mapq:
                count += 1
    return count

# Count the number of reads marked as duplicates
def count_marked_duplicates(bam_path):
    count = 0
    with pysam.AlignmentFile(bam_path, "rb") as bam:
        for read in bam:
            if read.is_duplicate:
                count += 1
    return count

# Count the number of reads with read group information
def count_reads_with_read_group(bam_path):
    reads_with_rg = 0
    with pysam.AlignmentFile(bam_path, "rb") as bam:
        for read in bam:
            if not read.is_secondary and not read.is_supplementary:
                if read.has_tag("RG"):
                    reads_with_rg += 1
    return reads_with_rg

# Returns the first n lines of a BAM file
def print_bam_first_n_lines(path, n_lines):
    lines = []
    with pysam.AlignmentFile(path, "rb") as bam:
        for i, read in enumerate(bam):
            if i >= n_lines:
                break
            lines.append(str(read).rstrip())
    return "\n".join(lines)

# Creates an array for depth at each BAM position (at a given BQ threshold and within a given BED)
def depth_array_BQ_bed(bam_path, chrom_lengths, BQ_threshold, BED_file, threads):
    
    # Get chromosome offsets to caclulate array indices
    offsets, genome_length = get_chrom_offsets(chrom_lengths)

    # Set coverage to 0 for all positions
    depth_array = np.zeros(genome_length, dtype=int)

    cmd = [
    "samtools", "depth",
    "--threads", str(threads),
    "-J",
    "-s",
    "--min-BQ", str(BQ_threshold), # Only bases with BQ >= threshold count towards depth
    "-b", str(BED_file), # Only bases within BED regions count towards depth
    bam_path
    ]

    with subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    ) as proc:

        for line in proc.stdout:
            chrom, pos_str, depth_str = line.split()
            pos = int(pos_str) - 1 # Convert position to 0-based
            depth = int(depth_str)
            genome_index = offsets[chrom] + pos

            # Add depth value to array
            depth_array[genome_index] = depth

    return depth_array