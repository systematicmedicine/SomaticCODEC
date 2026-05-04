"""
Calculates the percentage of somatic SNVs that are clonal
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_snv_clonality_metrics:
    input:
        vcf = EX.CALLED_SNVS
    output:
        metrics_json = EX.MET_SNV_CLONALITY
    log:
        L.EX_SNV_CLONALITY_METRICS
    benchmark:
        B.EX_SNV_CLONALITY_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate clonality metrics
        clonality_metrics.py \
            --vcf {input.vcf} \
            --json {output.metrics_json} \
            --log {log} 2>> {log}
        """