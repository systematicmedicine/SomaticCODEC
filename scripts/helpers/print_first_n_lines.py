"""
--- print_first_n_lines.py ---

Functions for printing the first n lines of pipeline output files.

Authors: 
    - Joshua Johnstone
    - Chat-GPT

"""
from pathlib import Path
from scripts.helpers.fastq_helpers import print_fastq_first_n_lines
from scripts.helpers.vcf_helpers import print_vcf_first_n_lines
from scripts.helpers.bed_helpers import print_bed_first_n_lines
from scripts.helpers.tabular_helpers import print_tabular_first_n_lines
from scripts.helpers.bam_helpers import print_bam_first_n_lines
from scripts.helpers.sam_helpers import print_sam_first_n_lines
from scripts.helpers.bcf_helpers import print_bcf_first_n_lines
from scripts.helpers.fasta_helpers import print_fasta_first_n_lines

# Calls the appropriate function based on file suffix
def print_first_n_lines(path, n_lines):
    path = Path(path)
    suffixes = "".join(path.suffixes)
    suffix = path.suffix

    if suffixes == ".vcf.gz" or suffix == ".vcf":
        return print_vcf_first_n_lines(path, n_lines)
    
    if suffixes == ".fastq.gz" or suffix == ".fastq":
        return print_fastq_first_n_lines(path, n_lines)
    
    if suffix == ".bed":
        return print_bed_first_n_lines(path, n_lines)
    
    elif suffix in [".csv", ".tsv", ".txt"]:
        return print_tabular_first_n_lines(path, n_lines)
    
    elif suffix == ".bam":
        return print_bam_first_n_lines(path, n_lines)
    
    elif suffix == ".sam":
        return print_sam_first_n_lines(path, n_lines)
    
    elif suffix == ".bcf":
        return print_bcf_first_n_lines(path, n_lines)
    
    elif suffixes == ".fasta.gz" or suffix == ".fasta":
        return print_fasta_first_n_lines(path, n_lines)
    
    else:
        return (f"Unsupported file type for printing first n lines: {path.suffix}")