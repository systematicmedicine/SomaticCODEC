"""
Calculates the number of multimapping reads following raw alignment
"""

from definitions.paths.io import ex as EX

rule ex_multimapping_raw_metrics:
    input:
        bam = EX.RAW_BAM
    output:
        json = EX.MET_MULTIMAPPING_RAW
    log:
        "logs/{ex_sample}/ex_multimapping_raw_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_multimapping_raw_metrics.benchmark.txt"
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