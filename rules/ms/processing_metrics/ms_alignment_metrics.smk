"""
Generates MS alignment metrics
"""

rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt"
    log:
        "logs/{ms_sample}/ms_alignment_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate alignment metrics
        samtools flagstat {input.bam} > {output.stats} 2>> {log}
        """ 