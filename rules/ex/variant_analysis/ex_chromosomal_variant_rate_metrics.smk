"""
Compares variant rate between chromosomes
"""
rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        metrics = "results/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"
    params:
        included_chromosomes = config["sci_params"]["global"]["included_chromosomes"]
    log:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate chromosomal variant rate metrics
        ex_chromosomal_variant_rate_metrics.py \
            --vcf {input.vcf} \
            --fai {input.fai} \
            --metrics {output.metrics} \
            --included_chromosomes {params.included_chromosomes} \
            --log {log} 2>> {log}
        """
