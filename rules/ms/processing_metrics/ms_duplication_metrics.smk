"""
Generates ms duplication metrics
"""

from definitions.paths.io import ms as MS

rule ms_duplication_metrics:
    input:
        dedup_metrics = MS.MET_REMOVE_DUPLICATES
    output:
        duplication_metrics = MS.MET_DUPLICATION
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_duplication_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_duplication_metrics.benchmark.txt"
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
