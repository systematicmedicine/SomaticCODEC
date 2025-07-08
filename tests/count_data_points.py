"""
--- count_data_points.py ---

Functions for obtaining the number of data points from pipeline output files.

Author: Joshua Johnstone

"""
import gzip
from pathlib import Path
import pysam

# Gets list of all files to be checked
def get_all_file_paths(outputs_to_check, ms_samples, ex_lanes, ex_samples):
    all_files = set()
    for _, row in outputs_to_check.iterrows():

        for sample in ms_samples + ex_lanes + ex_samples:
            path_template = row["file_path"]

            if "{ms_sample}" in path_template:
                path_str = path_template.format(ms_sample=sample)

            elif "{ex_lane}" in path_template:
                path_str = path_template.format(ex_lane=sample)

            elif "{ex_sample}" in path_template:
                path_str = path_template.format(ex_sample=sample)
                
            else:
                path_str = path_template
            all_files.add(path_str)
    return all_files

# Determines which data counting function to call based on file suffix
def count_data_points(path):
    path = Path(path)
    suffixes = "".join(path.suffixes)
    suffix = path.suffix

    if suffixes == ".vcf.gz" or suffix == ".vcf":
        return count_vcf_data_points(path)
    
    if suffixes == ".fastq.gz" or suffix == ".fastq":
        return count_fastq_data_points(path)
    
    if suffix == ".bed":
        return count_bed_data_points(path)
    
    elif suffix in [".csv", ".tsv", ".txt"]:
        return count_tabular_data_points(path)
    
    elif suffix == ".bam":
        return count_bam_data_points(path)
    
    elif suffix == ".sam":
        return count_sam_data_points(path)
    
    elif suffix == ".bcf":
        return count_bcf_data_points(path)
    
    elif suffixes == ".fasta.gz" or suffix == ".fasta":
        return count_fasta_data_points(path)
    
    else:
        raise ValueError(f"Unsupported file type for data point counting: {path.suffix}")

# Counts the number of data rows in a BED file
def count_bed_data_points(path):
    with open(path, 'r') as file:
        return sum(1 for _ in file)

# Counts the number of data rows in a VCF file
def count_vcf_data_points(path):
    path = Path(path)
    open_func = gzip.open if "".join(path.suffixes[-2:]) == ".vcf.gz" else open
    count = 0
    with open_func(path, 'rt') as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith("#"):
                count += 1
    return count

# Counts the number of data rows in a tabular file
def count_tabular_data_points(path):
    count = 0
    with open(path) as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith("#"):
                count += 1
    return count

# Counts the number of reads in a FASTQ file
def count_fastq_data_points(path):
    count = 0
    open_func = open
    if str(path).endswith(".gz"):
        open_func = gzip.open

    with open_func(path, 'rt') as file:
        for _ in file:
            count += 1
    return count // 4

# Counts the number of reads in a SAM file
def count_sam_data_points(path):
    count = 0
    with open(path, 'r') as file:
        for line in file:
            if not line.startswith('@'):
                count += 1
    return count

# Counts the number of reads in a BAM file
def count_bam_data_points(path):
    with pysam.AlignmentFile(path, "rb") as bam:
        return sum(1 for _ in bam)
    
# Counts the number of variant records in a BCF file
def count_bcf_data_points(path):
    count = 0
    with pysam.VariantFile(path, "rb") as file:
        for _ in file.fetch():
            count += 1
    return count

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
