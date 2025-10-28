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
        ref = config["sci_params"]["global"]["reference_genome"],
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai",
        included_chromsomes_bed = "tmp/downloads/included_chromosomes.bed"
    output:
        intermediate_pileup = temp("tmp/{ms_sample}/{ms_sample}_ms_pileup.bcf"),
        vcf_germ = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf"
    params:
        max_base_qual = config["sci_params"]["ms_germline_risk"]["max_base_qual"],
        max_depth = config["sci_params"]["ms_germline_risk"]["max_depth"],
        min_alt_vaf = config["sci_params"]["ms_germline_risk"]["min_alt_vaf"],
        min_base_qual = config["sci_params"]["ms_germline_risk"]["min_base_qual"],
        min_map_qual = config["sci_params"]["ms_germline_risk"]["min_map_qual"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_germline_risk.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_risk.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
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
        --output-type b{params.compression_level} \
        --output {output.intermediate_pileup} \
        {input.bam} 2>> {log}

        bcftools view \
        --threads {threads} \
        --include '(SUM(AD[0:*]) - AD[0:0]) / FMT/DP >= {params.min_alt_vaf}' \
        --output {output.vcf_germ} \
        {output.intermediate_pileup} 2>> {log}
        """