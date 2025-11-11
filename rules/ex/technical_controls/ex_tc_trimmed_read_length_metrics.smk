"""
Calculates the length of reads post trimming, outputs percentiles and zero-length reads
"""

rule ex_tc_trimmed_read_length_metrics:
    input:
        r1 = "tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_tc.fastq.gz",
        r2 = "tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_tc.fastq.gz"
    output:
        json = "metrics/{ex_technical_control}/{ex_technical_control}_trimmed_read_length_metrics_tc.json"
    params:
        sample = "{ex_technical_control}"
    log:
        "logs/{ex_technical_control}/ex_tc_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_technical_control}/ex_tc_trimmed_read_length_metrics.benchmark.txt" 
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate trimmed read length metrics
        ex_tc_trimmed_read_length_metrics.py \
            --r1 {input.r1} \
            --r2 {input.r2} \
            --json {output.json} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
