"""
Collects alignment metrics from the experimental bam mapped to the reference genome
"""
rule ex_map_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
    log:
        "logs/{ex_sample}/ex_map_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_map_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate alignment metrics        
        samtools flagstat {input.bam} > {output.txt} 2>> {log}
        """