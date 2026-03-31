"""
Compares variant rate between chromosomes
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = EX.CALLED_SNVS,
        fai = config["sci_params"]["reference_files"]["genome"] + ".fai"
    output:
        metrics = EX.MET_CHROM_VARIANT_RATE
    params:
        included_chromosomes = config["sci_params"]["shared"]["included_chromosomes"]
    log:
        L.EX_CHROMOSOMAL_VARIANT_RATE_METRICS
    benchmark:
        B.EX_CHROMOSOMAL_VARIANT_RATE_METRICS
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
