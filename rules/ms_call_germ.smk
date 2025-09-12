"""
--- ms_call_germ.smk ---

Rules for calling and filtering germline variants

Input: 
    - Aligned, sorted and deduplicated BAM
    - GCRh38 human reference genome
Output: 
    - Filtered VCF file

Authors: 
    - Ben Barry
    - Joshua Johnstone
    
"""

# Call candidate germline variants
# - Germline variants are called only on chromosomes defined in config[chroms][included_chromosomes]
rule ms_candidate_germ_variants:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam",
        ref = config["files"]["reference_genome"],
        fai = config["files"]["reference_genome"] + ".fai"
    output:
        intermediate_pileup = "tmp/{ms_sample}/{ms_sample}_ms_pileup.vcf",
        vcf_candidate = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf"
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"],
        max_base_qual = config["rules"]["ms_candidate_germ_variants"]["max_base_qual"],
        max_depth = config["rules"]["ms_candidate_germ_variants"]["max_depth"],
        min_alt_vaf = config["rules"]["ms_candidate_germ_variants"]["min_alt_vaf"],
        min_base_qual = config["rules"]["ms_candidate_germ_variants"]["min_base_qual"],
        min_depth = config["rules"]["ms_candidate_germ_variants"]["min_depth"],
        min_map_qual = config["rules"]["ms_candidate_germ_variants"]["min_map_qual"]
    log:
        "logs/{ms_sample}/ms_candidate_germ_variants.log"
    benchmark:
        "logs/{ms_sample}/ms_candidate_germ_variants.benchmark.txt"
    threads:
        config["resources"]["threads"]["moderate"]
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
        --regions {params.included_chromosomes} \
        --output {output.intermediate_pileup} \
        {input.bam} 2>> {log}

        bcftools filter \
        --threads {threads} \
        --include 'FMT/DP >= {params.min_depth} && \
        (SUM(AD[0:*]) - AD[0:0]) / FMT/DP >= {params.min_alt_vaf}' \
        --output {output.vcf_candidate} \
        {output.intermediate_pileup} 2>> {log}
        """