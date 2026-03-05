"""
Calculates the number of multimapping reads following realignment of DSC reads
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_multimapping_dsc_metrics:
    input:
        bam = EX.REALIGNED_DSC
    output:
        json = EX.MET_MULTIMAPPING_DSC
    log:
        L.EX_MULTIMAPPING_DSC_METRICS
    benchmark:
        "logs/{ex_sample}/ex_multimapping_dsc_metrics.benchmark.txt"
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