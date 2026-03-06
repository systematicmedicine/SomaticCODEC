"""
Calculates the number of multimapping reads following realignment of DSC reads
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_multimapping_dsc_metrics:
    input:
        bam = EX.REALIGNED_DSC
    output:
        json = EX.MET_MULTIMAPPING_DSC
    log:
        L.EX_MULTIMAPPING_DSC_METRICS
    benchmark:
        B.EX_MULTIMAPPING_DSC_METRICS
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