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

# Creates a mask for genomic positions with low ms read depth
rule ms_low_depth_mask:
    input:
        markdup_bam = "tmp/{ms_sample}/{ms_sample}_markdup_map.bam",
        markdup_bai = "tmp/{ms_sample}/{ms_sample}_markdup_map.bai"
    output:
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed"),
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram.txt"
    params:
        threshold = config['lowdepth_mask_threshold'],
        intermediate_depth_per_base = temp("tmp/{ms_sample}/{ms_sample}_depth_per_base.txt"),
        intermediate_lowdepth = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.txt"),
        intermediate_lowdepth_sorted = temp("tmp/{ms_sample}/{ms_sample}_lowdepth_sorted.txt"),
        intermediate_depth_values = temp("tmp/{ms_sample}/{ms_sample}_depth_values.txt"),
        intermediate_depth_values_sorted = temp("tmp/{ms_sample}/{ms_sample}_depth_values_sorted.txt")
    shell:
        """
        samtools depth -aa {input.markdup_bam} > {params.intermediate_depth_per_base}
        awk -v threshold={params.threshold} '$3 < threshold {{print $1"\t"($2-1)"\t"$2}}' \
        {params.intermediate_depth_per_base} > {params.intermediate_lowdepth}
        sort {params.intermediate_lowdepth} -k1,1 -k2,2n > {params.intermediate_lowdepth_sorted}
        bedtools merge -i {params.intermediate_lowdepth_sorted} > {output.bed}

        awk '{{print $3}}' {params.intermediate_depth_per_base} > {params.intermediate_depth_values}
        sort -n {params.intermediate_depth_values} > {params.intermediate_depth_values_sorted}
        uniq -c {params.intermediate_depth_values_sorted} > {output.depth_histogram}
        """

# Creates a mask genomic positions where germline variants have been called in ms sample
    # For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles. 
    # For insertions and SNV's, the BED region is length 1
rule ms_germline_variants_mask:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    output:
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs_unformatted.bed")
    params:
        intermediate_uncompressed = temp("tmp/{ms_sample}/{ms_sample}_ms_candidate_variants_uncompressed.vcf")
    shell:
        """
        zcat {input.vcf} > {params.intermediate_uncompressed}
        
        vcf2bed --deletions < {params.intermediate_uncompressed} > {output.ms_germ_del_bed}
        vcf2bed --insertions < {params.intermediate_uncompressed} > {output.ms_germ_ins_bed}
        vcf2bed --snvs < {params.intermediate_uncompressed} > {output.ms_germ_snv_bed}
        """

# Removes additional columns from germline variants mask to align with standard BED format
rule format_germline_variant_mask:
    input:
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs_unformatted.bed"
    output:
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs.bed")
    shell:
        """
        cut -f1-3 {input.ms_germ_del_bed} > {output.ms_germ_del_bed}
        cut -f1-3 {input.ms_germ_ins_bed} > {output.ms_germ_ins_bed}
        cut -f1-3 {input.ms_germ_snv_bed} > {output.ms_germ_snv_bed}        
        """

# Combines all masks into a single BED file
rule ms_combine_masks:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed"
    output:
        combined_bed = temp("tmp/{ms_sample}/{ms_sample}_combined_mask.bed")
    params:
        intermediate_cat = temp("tmp/{ms_sample}/{ms_sample}_masks_cat.bed"),
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.bed")
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_del_bed} \
        {input.ms_germ_ins_bed} \
        {input.ms_germ_snv_bed} > {params.intermediate_cat}
        
        sort {params.intermediate_cat} -k1,1 -k2,2n > {params.intermediate_sorted}

        bedtools merge -i {params.intermediate_sorted} > {output.combined_bed}
        """
