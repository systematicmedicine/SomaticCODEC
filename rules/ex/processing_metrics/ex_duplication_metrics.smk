"""
Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_duplication_metrics:
    input:
        umi_metrics = EX.MET_GROUP_BY_UMI
    params:
        sample = "{ex_sample}"
    output:
        json = EX.MET_DUPLICATION
    log:
        L.EX_DUPLICATION_METRICS
    benchmark:
        "logs/{ex_sample}/ex_duplication_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate duplication metrics
        ex_duplication_metrics.py \
            --umi_metrics {input.umi_metrics} \
            --json {output.json} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
