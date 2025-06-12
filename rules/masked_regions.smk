"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants
    - Illumina low confidence regions
    - Low depth regions from raw alignment (ms)
    - Known low mappability regions
    - Heterozygous regions from filtered germline variants (ms)
    
Output: BED file containing all regions to mask

Author: Joshua Johnstone

"""

rule low_depth_bed:
    input:
    output:
    shell: