"""
--- masked_regions.smk ---

Rules for masking genomic regions where somatic variant cannot be confidently called.

Inputs:
    - gnomAD common variants (1% VAF)
    - GIAB all difficult regions
    - Low depth regions from ms raw alignment (<30x)
    - ms germline variant positions
    
Output: BED file containing all regions to mask

Authors:
    - Joshua Johnstone
    - Benjamin Barry

"""

# Creates a mask for low depth (<30x) positions of ms raw alignment
rule ms_low_depth_mask:
    input:
        markdup_bam = "tmp/{ms_sample}/{ms_sample}_markdup.bam",
        markdup_bai = "tmp/{ms_sample}/{ms_sample}_markdup.bai"
    output:
        depth_stats = "metrics/{ms_sample}/{ms_sample}_depth_stats.txt",
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed")
    params:
        threshold = 30
    shell:
        """
        samtools depth -aa {input.markdup_bam} > {output.depth_stats}
        awk '$3 < {params.threshold} {{print $1"\t"$2-1"\t"$2}}' {output.depth_stats} | \
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.bed}     
        """

# Creates a mask for ms germline variant positions
    # For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles. 
    # For insertions and SNV's, the BED region is length 1
rule ms_germline_variants_bed:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz"
    output:
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_del.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_ins.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_snv.bed")
    shell:
        """
        # Convert filtered VCF to BED format
        zcat {input.vcf} | vcf2bed --deletions > {output.ms_germ_del_bed}
        zcat {input.vcf} | vcf2bed --insertions > {output.ms_germ_ins_bed}
        zcat {input.vcf} | vcf2bed --snvs > {output.ms_germ_snv_bed}
        """

rule format_germline_variant_beds:
    input:
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_del.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_ins.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_snv.bed"
    output:
        ms_germ_del_bed_format = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_del_format.bed"),
        ms_germ_ins_bed_format = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_ins_format.bed"),
        ms_germ_snv_bed_format = temp("tmp/{ms_sample}/{ms_sample}_GL_variants_snv_format.bed")
    shell:
        """
        cut -f1-3 {input.ms_germ_del_bed} > {output.ms_germ_del_bed_format}
        cut -f1-3 {input.ms_germ_ins_bed} > {output.ms_germ_ins_bed_format}
        cut -f1-3 {input.ms_germ_snv_bed} > {output.ms_germ_snv_bed_format}        
        """

# Combines all masks into one BED file
rule ms_combine_masks:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_del_format.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_ins_format.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_GL_variants_snv_format.bed"
    output:
        combined_bed = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed" # Make temporary once pipeline development is complete
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_del_bed} \
        {input.ms_germ_ins_bed} \
        {input.ms_germ_snv_bed} | \
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.combined_bed}
        """
