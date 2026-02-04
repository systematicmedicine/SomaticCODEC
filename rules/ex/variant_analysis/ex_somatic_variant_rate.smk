"""
Calculate the somatic variant rate
"""
rule ex_somatic_variant_rate:
    input:
        vcf_all = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf"
    output:
        results = "results/{ex_sample}/{ex_sample}_somatic_variant_rate.json"
    log:
        "logs/{ex_sample}/ex_somatic_variant_rate.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_rate.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate somatic variant rate
        ex_somatic_variant_rate.py \
            --vcf_all {input.vcf_all} \
            --results {output.results} \
            --log {log} 2>> {log}
        """
