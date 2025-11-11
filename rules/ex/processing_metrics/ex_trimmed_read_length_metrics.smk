"""
Calculates the length of reads post trimming, outputs percentiles and zero-length reads
"""
rule ex_trimmed_read_length_metrics:
    input:
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_trimmed_read_length_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.benchmark.txt" 
    resources:
        memory = config["infrastructure"]["memory"]["light"]
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
