"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants (1% VAF)
    - GIAB all difficult regions
    - Low depth regions from ms raw alignment (<30x)
    - ms germline variant positions
    
Output: BED file containing all regions to mask

Author: Joshua Johnstone

"""

# Creates a mask for low depth (<30x) positions of ms raw alignment
rule ms_low_depth_mask:
    input:
        markdup_bam = "tmp/{ms_sample}/{ms_sample}_markdup.bam",
        markdup_bai = "tmp/{ms_sample}/{ms_sample}_markdup.bai"
    output:
        depth_stats = "metrics/{ms_sample}/{ms_sample}_depth.txt",
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed")
    params:
        threshold = 30
    shell:
        """
        samtools depth -aa {input.markdup_bam} > {output.depth_stats}
        awk '$3 < {params.threshold} {{print $1"\\t"$2-1"\\t"$2}}' {output.depth_stats} > {output.bed}
       
        """

# Creates a mask for ms germline variant positions
#When using --deletions, the stop value of the BED output is determined by the length difference between ALT and REF alleles. 
    #Use of --insertions or --snvs yields a one-base BED element.
rule ms_germline_variants_bed:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz"
    output:
        del_bed= temp("tmp/{ms_sample}/{ms_sample}_GL_variants_del.bed"),
        in_bed= temp("tmp/{ms_sample}/{ms_sample}_GL_variants_in.bed"),
        snv_bed = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_snv.bed"),
        bed = temp("tmp/{ms_sample}/{ms_sample}_GL_variants.bed")
    shell:
        """
        # Convert filtered VCF to BED format
        zcat {input.vcf} | vcf2bed --deletions > {output.del_bed}
        zcat {input.vcf} | vcf2bed --insertions > {output.in_bed}
        zcat {input.vcf} | vcf2bed --snvs > {output.snv_bed}

        # Concatenate all into a single BED file, preserving exact regions
        cat {output.del_bed} {output.in_bed} {output.snv_bed} | \
            sort -k1,1 -k2,2n > {output.bed}
            
        """

# Combines all masks into one bed file
rule ms_combine_masks:
    input:
        gnomAD_bed = "reference/gnomad_common_af01_merged.bed",
        GIAB_bed = "reference/GRCh38_alldifficultregions.bed",
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germline_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants.bed"
    output:
        combined_bed = temp("tmp/{ms_sample}/{ms_sample}_combined.bed")
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germline_bed}
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.combined_bed}

        """