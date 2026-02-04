"""
Calculate duplex overlap metrics
"""
rule ex_duplex_overlap_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_duplex_overlap_metrics.json"
    log:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate duplex overlap metrics
        ex_duplex_overlap_metrics.py \
            --bam {input.bam} \
            --metrics {output.metrics} \
            --log {log} 2>> {log}
        """
