"""
--- ms_call_germ.smk ---

Rules for calling and filtering germline variants

Input: 
    - Aligned, sorted and deduplicated BAM
    - GCRh38 human reference genome
Output: 
    - Filtered VCF file

Author: Ben Barry

"""

# Call candidate germline variants
# - Germline variants are called only on chromosomes defined in config[chroms][included_chromosomes]
rule ms_candidate_germ_variants:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam",
        ref = config["files"]["reference_genome"],
        fai = config["files"]["reference_genome"] + ".fai",
        dictf = os.path.splitext(config["files"]["reference_genome"])[0] + ".dict"
    output:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    params:
        included_chromosomes = " -L ".join(config["chroms"]["included_chromosomes"]),
        base_quality_score_threshold = config["rules"]["ms_candidate_germ_variants"]["base_quality_score_threshold"],
        heterozygosity_rate = config["rules"]["ms_candidate_germ_variants"]["heterozygosity_rate"],
        heterozygosity_stdev = config["rules"]["ms_candidate_germ_variants"]["heterozygosity_stdev"],
        indel_heterozygosity = config["rules"]["ms_candidate_germ_variants"]["indel_heterozygosity"],
        min_base_quality_score = config["rules"]["ms_candidate_germ_variants"]["min_base_quality_score"],
        max_alternate_alleles = config["rules"]["ms_candidate_germ_variants"]["max_alternate_alleles"],
        pcr_indel_model = config["rules"]["ms_candidate_germ_variants"]["pcr_indel_model"],
        standard_min_confidence_threshold = config["rules"]["ms_candidate_germ_variants"]["standard_min_confidence_threshold"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
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
        gatk --java-options "-Xmx{resources.memory}g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            -L {params.included_chromosomes} \
            --native-pair-hmm-threads {threads} \
            --base-quality-score-threshold {params.base_quality_score_threshold} \
            --heterozygosity {params.heterozygosity_rate} \
            --heterozygosity-stdev {params.heterozygosity_stdev} \
            --indel-heterozygosity {params.indel_heterozygosity} \
            --min-base-quality-score {params.min_base_quality_score} \
            --max-alternate-alleles {params.max_alternate_alleles} \
            --pcr-indel-model {params.pcr_indel_model} \
            --stand-call-conf {params.standard_min_confidence_threshold} 2>> {log}
        """