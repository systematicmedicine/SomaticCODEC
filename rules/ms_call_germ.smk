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
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")
    params:
        included_chromosomes="-L " + " -L ".join(config["chroms"]["included_chromosomes"])
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
            {params.included_chromosomes} \
            --native-pair-hmm-threads {threads} \
            --standard-min-confidence-threshold-for-calling 20 2>> {log}
        """