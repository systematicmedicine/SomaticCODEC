"""
Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
"""
rule ex_duplication_metrics:
    input:
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"
    params:
        sample = "{ex_sample}"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_duplication_metrics.json"
    log:
        "logs/{ex_sample}/ex_duplication_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplication_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate duplication metrics
        ex_duplication_metrics.py \
            --umi_metrics {input.umi_metrics} \
            --json {output.json} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
