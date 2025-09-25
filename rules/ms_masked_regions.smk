# ==============================================================================================
#   ms_masked_regions.smk
#
#   Rules for masking genomic postions where somatic variants cannot be confidently called.
#       - Positions that may contain germline variants (based on MS sample)
#       - Positions with low MS depth
#       - Positions from precomputed masks (defined in config)
#   
#   Precomputed masks worth considering:
#       - gnomAD common germline variants
#       - Genome in a Bottle difficult genomic regions
#       - RepBase RepeatMask
#
#   Authors:
#       - Joshua Johnstone
#       - James Phie
#       - Cameron Fraser
# ==============================================================================================


import helpers.get_metadata as md


# ----------------------------------------------------------------------------------------------
#   RULE ms_germline_risk
#
#   Uses matched sample BAM to identify positions that may contain germline variants. 
# 
#   Notes:
#       - Designed to favour sensitivty over specificity
# ----------------------------------------------------------------------------------------------
rule ms_germline_risk:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam",
        ref = config["files"]["reference_genome"],
        fai = config["files"]["reference_genome"] + ".fai",
        included_chromsomes_bed = "tmp/downloads/included_chromosomes.bed"
    output:
        intermediate_pileup = temp("tmp/{ms_sample}/{ms_sample}_ms_pileup.vcf"),
        vcf_germ = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf"
    params:
        max_base_qual = config["rules"]["ms_germline_risk"]["max_base_qual"],
        max_depth = config["rules"]["ms_germline_risk"]["max_depth"],
        min_alt_vaf = config["rules"]["ms_germline_risk"]["min_alt_vaf"],
        min_base_qual = config["rules"]["ms_germline_risk"]["min_base_qual"],
        min_map_qual = config["rules"]["ms_germline_risk"]["min_map_qual"]
    log:
        "logs/{ms_sample}/ms_germline_risk.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_risk.benchmark.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        bcftools mpileup \
        --threads {threads} \
        --fasta-ref {input.ref} \
        --annotate AD,DP \
        --min-MQ {params.min_map_qual} \
        --min-BQ {params.min_base_qual} \
        --max-BQ {params.max_base_qual} \
        --max-depth {params.max_depth} \
        --no-BAQ \
        --regions-file {input.included_chromsomes_bed} \
        --output {output.intermediate_pileup} \
        {input.bam} 2>> {log}

        bcftools view \
        --threads {threads} \
        --include '(SUM(AD[0:*]) - AD[0:0]) / FMT/DP >= {params.min_alt_vaf}' \
        --output {output.vcf_germ} \
        {output.intermediate_pileup} 2>> {log}
        """


# ----------------------------------------------------------------------------------------------
#   RULE ms_germline_mask
#
#   Creates a BED file from germline risk VCF 
# 
#   Notes:
#       - For deletions, the stop value of the BED region is determined by the length difference 
#           between ALT and REF alleles. 
#       - For insertions and SNV's, the BED region is length 1
# ----------------------------------------------------------------------------------------------
rule ms_germline_mask:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf",
        ref_fai = config["files"]["reference_genome"] + ".fai"
    output:
        intermediate_del_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unformatted.bed"),
        intermediate_ins_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unformatted.bed"),
        intermediate_snv_unformatted = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs_unformatted.bed"),
        intermediate_del_unpadded = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions_unpadded.bed"),
        intermediate_ins_unpadded = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions_unpadded.bed"),
        ms_germ_del_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_deletions.bed"),
        ms_germ_ins_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_insertions.bed"),
        ms_germ_snv_bed = temp("tmp/{ms_sample}/{ms_sample}_germ_snvs.bed")
    params:
        indel_padding_bases = config["rules"]["ms_germline_mask"]["indel_padding_bases"]
    log:
        "logs/{ms_sample}/ms_germline_variants_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_variants_mask.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """        
        vcf2bed --deletions < {input.vcf} > {output.intermediate_del_unformatted} 2>> {log}
        vcf2bed --insertions < {input.vcf} > {output.intermediate_ins_unformatted} 2>> {log}
        vcf2bed --snvs < {input.vcf} > {output.intermediate_snv_unformatted} 2>> {log}

        cut -f1-3 {output.intermediate_del_unformatted} > {output.intermediate_del_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_ins_unformatted} > {output.intermediate_ins_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_snv_unformatted} > {output.ms_germ_snv_bed} 2>> {log}

        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_del_unpadded} > {output.ms_germ_del_bed} 2>> {log}
        
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_ins_unpadded} > {output.ms_germ_ins_bed} 2>> {log}
        """


# ----------------------------------------------------------------------------------------------
#   RULE ms_low_depth_mask
#
#   Creates a mask for genomic positions with low read depth in matched sample
#
#   Notes:
#   - Deletions are counted towards depth (-J flag)   
#   - Overlapping r1 and r2 reads are counted once only (-s flag)
# ----------------------------------------------------------------------------------------------
rule ms_low_depth_mask:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam",
        bai = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam.bai"
    output:
        bed = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.bed"),
        intermediate_depth_per_base = temp("tmp/{ms_sample}/{ms_sample}_depth_per_base.txt"),
        intermediate_lowdepth = temp("tmp/{ms_sample}/{ms_sample}_lowdepth.txt"),
        intermediate_lowdepth_sorted = temp("tmp/{ms_sample}/{ms_sample}_lowdepth_sorted.txt")
    params:
        min_base_qual = config["rules"]["ms_germline_risk"]["min_base_qual"],
        min_map_qual = config["rules"]["ms_germline_risk"]["min_map_qual"],
        threshold = config["rules"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_low_depth_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth_mask.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        samtools depth \
        -aa \
        --min-BQ {params.min_base_qual} \
        --min-MQ {params.min_map_qual} \
        -s \
        -J \
        {input.bam} > {output.intermediate_depth_per_base} 2>> {log}

        awk -v threshold={params.threshold} '$3 < threshold {{print $1"\t"($2-1)"\t"$2}}' \
        {output.intermediate_depth_per_base} > {output.intermediate_lowdepth} 2>> {log}

        sort {output.intermediate_lowdepth} -k1,1V -k2,2n > {output.intermediate_lowdepth_sorted} 2>> {log}

        bedtools merge -i {output.intermediate_lowdepth_sorted} > {output.bed} 2>> {log}
        """


# ----------------------------------------------------------------------------------------------
#   RULE combine_masks
#
#   Combines all masks into a single BED file
# ----------------------------------------------------------------------------------------------
rule combine_masks:
    input:
        precomputed_masks = expand("{mask}", mask=config["files"]["precomputed_masks"]),
        excluded_chromosomes_bed = "tmp/downloads/excluded_chromosomes.bed",
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        fai = config["files"]["reference_genome"] + ".fai" 
    output:
        combined_bed = temp("tmp/{ms_sample}/{ms_sample}_combined_mask.bed"),
        intermediate_cat = temp("tmp/{ms_sample}/{ms_sample}_masks_cat.bed"),
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.bed")
    log:
        "logs/{ms_sample}/combine_masks.log"
    benchmark:
        "logs/{ms_sample}/combine_masks.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        cat {input.precomputed_masks} \
        {input.excluded_chromosomes_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_del_bed} \
        {input.ms_germ_ins_bed} \
        {input.ms_germ_snv_bed} > {output.intermediate_cat} 2>> {log}
        
        bedtools sort -faidx {input.fai} -i {output.intermediate_cat} > {output.intermediate_sorted} 2>> {log}

        bedtools merge -i {output.intermediate_sorted} > {output.combined_bed} 2>> {log}
        """

# ----------------------------------------------------------------------------------------------
#   RULE generate_include_bed
#
#   Generate a BED file of regions eligible for variant calling
# 
#   Notes:
#       - Inverse of combined mask
# ----------------------------------------------------------------------------------------------
rule generate_include_bed:
    input:
        ms_samples = config["files"]["ms_samples_metadata"],
        mask_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_combined_mask.bed"
        ),
        fai = config["files"]["reference_genome"] + ".fai"
    output:
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    log:
        "logs/{ex_sample}/generate_include_bed.log"
    benchmark:
        "logs/{ex_sample}/generate_include_bed.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed} 2>> {log}
        """