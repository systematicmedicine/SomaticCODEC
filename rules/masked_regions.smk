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
        markdup_bam = "tmp/{ms_sample_name}/{ms_sample_name}_markdup.bam",
        markdup_bai = "tmp/{ms_sample_name}/{ms_sample_name}_markdup.bai"
    output:
        depth_stats = "metrics/{ms_sample_name}/{ms_sample_name}_depth_stats.txt",
        bed = temp("tmp/{ms_sample_name}/{ms_sample_name}_lowdepth.bed")
    params:
        threshold = 30
    shell:
        """
        samtools depth -aa {input.markdup_bam} > {output.depth_stats}
        awk '$3 < {params.threshold} {{print $1"\t"$2-1"\t"$2}}' {output.depth_stats} | \
        sort -k1,1 -k2,2n \
        bedtools merge -i - > {output.bed}     
        """

# Creates a mask for ms germline variant positions
    # For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles. 
    # For insertions and SNV's, the BED region is length 1
rule ms_germline_variants_bed:
    input:
        vcf = "tmp/{ms_sample_name}/{ms_sample_name}_ms_filter_pass_variants.vcf.gz"
    output:
        ms_germ_del_bed = temp("tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_del.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_ins.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_snv.bed")
    shell:
        """
        # Convert filtered VCF to BED format
        zcat {input.vcf} | vcf2bed --deletions > {output.ms_germ_del_bed}
        zcat {input.vcf} | vcf2bed --insertions > {output.ms_germ_ins_bed}
        zcat {input.vcf} | vcf2bed --snvs > {output.ms_germ_snv_bed}
        """

# Combines all masks into one BED file
rule ms_combine_masks:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        ms_lowdepth_bed = "tmp/{ms_sample_name}/{ms_sample_name}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_del.bed",
        ms_germ_ins_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_ins.bed",
        ms_germ_snv_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_snv.bed"
    output:
        combined_bed = "tmp/{ms_sample_name}/{ms_sample_name}_combined_mask.bed" # Make temporary once pipeline development is complete
    shell:
        """
        cat {input.gnomAD_bed} \
        {input.GIAB_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_del_bed} \
        {input.ms_germ_ins_bed} \
        {input.ms_germ_snv_bed} \
        sort -k1,1 -k2,2n | \
        bedtools merge -i - > {output.combined_bed}
        """

# Generates metrics for each BED file
rule masking_metrics:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        ms_lowdepth_bed = "tmp/{ms_sample_name}/{ms_sample_name}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_del.bed",
        ms_germ_ins_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_ins.bed",
        ms_germ_snv_bed = "tmp/{ms_sample_name}/{ms_sample_name}_GL_variants_snv.bed",
        combined_bed = "tmp/{ms_sample_name}/{ms_sample_name}_combined_mask.bed",
        ref_index = config['GRCh38_path'] + ".fai"
    output:
        mask_metrics = "metrics/{ms_sample_name}/{ms_sample_name}_mask_metrics.txt"
    shell:
        """
        total_genome_bp=$(awk '{{sum += $2}} END {{print sum}}' {input.ref_index})

        printf "Mask File\\tMasked bases\\t%% of ref genome\\n" > {output.mask_metrics}

        for bed in \\
            {input.gnomAD_bed} \\
            {input.GIAB_bed} \\
            {input.ms_lowdepth_bed} \\
            {input.ms_germ_del_bed} \\
            {input.ms_germ_ins_bed} \\
            {input.ms_germ_snv_bed} \\
            {input.combined_bed}
        do
            name=$(basename "$bed")
            masked_bp=$(bedtools sort -i "$bed" | bedtools merge -i - | awk '{{sum += $3 - $2}} END {{print sum}}')
            pct=$(awk -v masked="$masked_bp" -v total="$total_genome_bp" 'BEGIN {{printf "%.2f", (masked / total) * 100}}')
            printf "%s\\t%s\\t%s%%\\n" "$name" "$masked_bp" "$pct" >> {output.mask_metrics}
        done
        """
