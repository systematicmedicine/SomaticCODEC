"""
Calculate the somatic variant rate
"""

from definitions.paths.io import ex as EX

rule ex_somatic_variant_rate:
    input:
        vcf_all = EX.CALL_SOMATIC_SNV_INT3
    output:
        results = EX.MET_SOMATIC_VARIANT_RATE
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
