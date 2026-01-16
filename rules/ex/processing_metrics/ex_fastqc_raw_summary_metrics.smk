"""
Generates a summary of key metrics for ex raw fastqc reports
"""
rule ex_fastqc_raw_summary_metrics:
    input:
        fastqc_files = ["metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt",
        "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt"]
    output:
        json_files = ["metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json",
        "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json"]
    params:
        sample = "{ex_lane}"
    log:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate fastqc summary metrics
        fastqc_summary_metrics.py \
            --fastqc_files {input.fastqc_files} \
            --json_files {output.json_files} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
