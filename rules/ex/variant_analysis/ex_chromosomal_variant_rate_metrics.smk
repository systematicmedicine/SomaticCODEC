"""
Compares variant rate between chromosomes
"""

from definitions.paths.io import ex as EX

rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = EX.CALLED_SNVS,
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        metrics = EX.MET_CHROM_VARIANT_RATE
    params:
        included_chromosomes = config["sci_params"]["shared"]["included_chromosomes"]
    log:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"
    threads:
        1
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
