"""
Calculates the percentage of germline variants that are clonal
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_germline_clonality_metrics:
    input:
        vcf = MS.PILEUP_DEPTH
    output:
        json = MS.MET_GERMLINE_CLONALITY
    log:
        L.MS_GERMLINE_CLONALITY_METRICS
    benchmark:
        B.MS_GERMLINE_CLONALITY_METRICS
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    threads:
        1
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate clonality metrics
        clonality_metrics.py \
            --vcf {input.vcf} \
            --json {output.json} \
            --log {log} 2>> {log}
        """
