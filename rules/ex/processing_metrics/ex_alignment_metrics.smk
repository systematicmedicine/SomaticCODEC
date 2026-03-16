"""
Collects alignment metrics from the experimental bam mapped to the reference genome
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_alignment_metrics:
    input:
        bam = EX.RAW_BAM
    output:
        txt = EX.MET_ALIGNMENT
    log:
        L.EX_ALIGNMENT_METRICS
    benchmark:
        B.EX_ALIGNMENT_METRICS
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