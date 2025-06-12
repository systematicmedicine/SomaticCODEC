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
# Finds and creates a mask for low depth regions of raw alignment
rule low_depth_mask:
    input:
        
    output:
    shell:

# Combines all masks into one bed file
rule combine_masks:
    input:
        gnomAD_bed = 
        illumina_bed = 
        lowdepth_bed =
        lowmap_bed = 
        het_bed = 
    output:
        combined_bed = 
    shell:
        """
        cat {input.gnomAD_bed} {input.illumina_bed} {input.lowdepth_bed} {input.lowmap_bed} {input.het_bed} | \
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.combined_bed}

        """