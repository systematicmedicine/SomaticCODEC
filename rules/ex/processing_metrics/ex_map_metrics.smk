"""
Collects alignment metrics from the experimental bam mapped to the reference genome
"""

from definitions.paths.io import ex as EX

rule ex_map_metrics:
    input:
        bam = EX.RAW_BAM
    output:
        txt = EX.MET_ALIGNMENT
    log:
        "logs/{ex_sample}/ex_map_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_map_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate alignment metrics        
        samtools flagstat {input.bam} > {output.txt} 2>> {log}
        """