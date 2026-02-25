"""
Calculates the count and percentage of bases lost during ex_trim_fastq
"""

from definitions.paths.io import ex as EX

rule ex_bases_trimmed:
    input:
        pre_r1 = EX.DEMUXD_FASTQ_R1,
        pre_r2 = EX.DEMUXD_FASTQ_R2,
        post_r1 = EX.TRIMMED_FASTQ_R1,
        post_r2 = EX.TRIMMED_FASTQ_R2
    output:
        json = EX.MET_BASES_TRIMMED
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_bases_trimmed.log"
    benchmark:
        "logs/{ex_sample}/ex_bases_trimmed.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate bases trimmed
        ex_bases_trimmed.py \
            --pre_r1 {input.pre_r1} \
            --pre_r2 {input.pre_r2} \
            --post_r1 {input.post_r1} \
            --post_r2 {input.post_r2} \
            --json {output.json} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """