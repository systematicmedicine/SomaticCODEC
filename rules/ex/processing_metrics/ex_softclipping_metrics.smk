"""
Quantifies soft clipping in final DSC
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_softclipping_metrics:
    input:
        dsc_final = EX.FILTERED_DSC
    output:
        metrics = EX.MET_SOFTCLIPPING
    log:
        L.EX_SOFTCLIPPING_METRICS
    benchmark:
        B.EX_SOFTCLIPPING_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate softclipping metrics
        ex_softclipping_metrics.py \
            --dsc_final {input.dsc_final} \
            --metrics {output.metrics} \
            --log {log} 2>> {log}
        """
