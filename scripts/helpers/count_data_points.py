"""
--- count_data_points.py ---

Functions for obtaining the number of data points from pipeline output files.

Authors: 
    - Joshua Johnstone
    - Chat-GPT

"""
from pathlib import Path
from scripts.helpers.fastq_helpers import count_fastq_data_points
from scripts.helpers.vcf_helpers import count_vcf_data_points
from scripts.helpers.bed_helpers import count_bed_data_points
from scripts.helpers.tabular_helpers import count_tabular_data_points
from scripts.helpers.bam_helpers import count_bam_data_points
from scripts.helpers.sam_helpers import count_sam_data_points
from scripts.helpers.bcf_helpers import count_bcf_data_points
from scripts.helpers.fasta_helpers import count_fasta_data_points

# Calls the appropriate data counting function based on file suffix
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
        return (f"Unsupported file type for data point counting: {path.suffix}")
