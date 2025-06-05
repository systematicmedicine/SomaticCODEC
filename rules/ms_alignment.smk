"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample trimmed and filtered reads

Input: Processed ms FASTQ files
Outputs: 
    - ms raw alignment BAM
    - Metrics files

Author: Joshua Johnstone

"""
# Indexes reference for use in alignment
rule index_ref:
    input:
        ref = ref
    output:
        "{input.ref}.bwt"
    shell:
        "bwa index {input.ref}"