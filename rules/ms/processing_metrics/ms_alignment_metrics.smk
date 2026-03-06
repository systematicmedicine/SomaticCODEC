"""
Generates MS alignment metrics
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ms_alignment_metrics:
    input:
        bam = MS.DEDUPED_BAM
    output:
        stats = MS.MET_ALIGNMENT
    log:
        L.MS_ALIGNMENT_METRICS
    benchmark:
        "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate alignment metrics
        samtools flagstat {input.bam} > {output.stats} 2>> {log}
        """ 