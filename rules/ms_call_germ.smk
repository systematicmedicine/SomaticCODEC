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

# Call candidate germline variants (no filtering)
rule ms_candidate_germ_variants:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_markdup_map.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = os.path.splitext(config["GRCh38_path"])[0] + ".dict"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")
    params:
        memory_limit_gb = config["ms_candidate_germ_variants"]["memory_limit_gb"]
    log:
        "logs/{ms_sample}/ms_candidate_germ_variants.log"
    benchmark:
        "logs/{ms_sample}/ms_candidate_germ_variants.benchmark.txt"
    threads:
         max(1, os.cpu_count() // 8)
    shell:
        """
        gatk --java-options "-Xmx{params.memory_limit_gb}g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            --native-pair-hmm-threads {threads} \
            --standard-min-confidence-threshold-for-calling 20 2>> {log}
        """