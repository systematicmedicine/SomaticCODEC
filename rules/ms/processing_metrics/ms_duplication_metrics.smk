"""
Generates ms duplication metrics
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_duplication_metrics:
    input:
        dedup_metrics = MS.MET_DEDUP_REPORT
    output:
        duplication_metrics = MS.MET_DUPLICATION
    params:
        sample = "{ms_sample}"
    log:
        L.MS_DUPLICATION_METRICS
    benchmark:
        B.MS_DUPLICATION_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate duplication metrics
        ms_duplication_metrics.py \
            --dedup_metrics {input.dedup_metrics} \
            --duplication_metrics {output.duplication_metrics} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
