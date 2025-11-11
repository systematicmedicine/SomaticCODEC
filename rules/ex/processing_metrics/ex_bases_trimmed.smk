"""
Calculates the count and percentage of bases lost during ex_trim_fastq
"""
rule ex_bases_trimmed:
    input:
        pre_r1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        pre_r2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        post_r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        post_r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_bases_trimmed.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_bases_trimmed.log"
    benchmark:
        "logs/{ex_sample}/ex_bases_trimmed.benchmark.txt"
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