"""
Calculates the number of multimapping reads following alignment
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ms_multimapping_metrics:
    input:
        bam = MS.DEDUPED_BAM
    output:
        json = MS.MET_MULTIMAPPING
    log:
        L.MS_MULTIMAPPING_METRICS
    benchmark:
        "logs/{ms_sample}/ms_multimapping_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate multimapping metrics
        multimapping_metrics.py \
        --bam {input.bam} \
        --json {output.json} \
        --log {log} 2>> {log}
        """