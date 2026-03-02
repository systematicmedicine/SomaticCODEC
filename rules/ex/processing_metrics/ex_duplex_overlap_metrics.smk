"""
Calculate duplex overlap metrics
"""

from definitions.paths.io import ex as EX

rule ex_duplex_overlap_metrics:
    input:
        bam = EX.FILTERED_DSC
    output:
        metrics = EX.MET_DUPLEX_OVERLAP
    log:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.benchmark.txt"
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
