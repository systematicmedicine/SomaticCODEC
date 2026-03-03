"""
Calculates the number of multimapping reads following realignment of DSC reads
"""

from definitions.paths.io import ex as EX

rule ex_multimapping_metrics_dsc:
    input:
        bam = EX.REALIGNED_DSC
    output:
        json = EX.MET_MULTIMAPPING_DSC
    log:
        "logs/{ex_sample}/ex_multimapping_metrics_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_multimapping_metrics_dsc.benchmark.txt"
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