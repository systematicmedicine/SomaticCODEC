"""
Calculate duplex overlap metrics
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_duplex_overlap_metrics:
    input:
        bam = EX.FILTERED_DSC
    output:
        metrics = EX.MET_DUPLEX_OVERLAP
    log:
        L.EX_DUPLEX_OVERLAP_METRICS
    benchmark:
        B.EX_DUPLEX_OVERLAP_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate duplex overlap metrics
        ex_duplex_overlap_metrics.py \
            --bam {input.bam} \
            --metrics {output.metrics} \
            --log {log} 2>> {log}
        """
