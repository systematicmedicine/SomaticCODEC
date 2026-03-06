"""
Calculates the distance to nearest SNV, for each SNV
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_snv_distance_metrics:
    input:
        vcf = EX.CALLED_SNVS
    output:
        metrics_json = EX.MET_SNV_DISTANCE
    log:
        L.EX_SNV_DISTANCE_METRICS
    benchmark:
        B.EX_SNV_DISTANCE_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate SNV distance metrics
        ex_snv_distance_metrics.py \
            --vcf {input.vcf} \
            --metrics_json {output.metrics_json} \
            --log {log} 2>> {log}
        """
