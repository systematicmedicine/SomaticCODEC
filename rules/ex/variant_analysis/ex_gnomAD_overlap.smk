"""
Determines how many called somatic variants are present in dataset of common germline variants
"""
rule ex_gnomAD_overlap:
    input:
        somatic_vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        germline_vcf = config["sci_params"]["global"]["known_germline_variants"],
        germline_tbi = config["sci_params"]["global"]["known_germline_variants"] + ".tbi"
    output:
        intermediate_somatic_bgz = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz"),
        intermediate_somatic_tbi = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz.tbi"),
        germline_matches = "results/{ex_sample}/{ex_sample}_germline_matches.vcf",
        metrics_file = "results/{ex_sample}/{ex_sample}_gnomAD_overlap_metrics.json"
    log:
        "logs/{ex_sample}/ex_gnomAD_overlap.log"
    benchmark:
        "logs/{ex_sample}/ex_gnomAD_overlap.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate gnomAD overlap metrics
        ex_gnomAD_overlap.py \
            --somatic_vcf {input.somatic_vcf} \
            --germline_vcf {input.germline_vcf} \
            --intermediate_somatic_bgz {output.intermediate_somatic_bgz} \
            --intermediate_somatic_tbi {output.intermediate_somatic_tbi} \
            --germline_matches {output.germline_matches} \
            --metrics_file {output.metrics_file} \
            --log {log} 2>> {log}
        """
