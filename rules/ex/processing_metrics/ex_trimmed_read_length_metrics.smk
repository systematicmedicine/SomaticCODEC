"""
Calculates the length of reads post trimming, outputs percentiles and zero-length reads
"""

from definitions.paths.io import ex as EX

rule ex_trimmed_read_length_metrics:
    input:
        r1 = EX.TRIMMED_FASTQ_R1,
        r2 = EX.TRIMMED_FASTQ_R2
    output:
        json = EX.MET_TRIM_READ_LENGTHS
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate trimmed read length metrics
        ex_trimmed_read_length_metrics.py \
            --r1 {input.r1} \
            --r2 {input.r2} \
            --sample {params.sample} \
            --json {output.json} \
            --log {log} 2>> {log}
        """
