"""
Generates a summary of key metrics for ex filter fastqc reports
"""

from definitions.paths.io import ex as EX

rule ex_fastqc_filter_summary_metrics:
    input:
        fastqc_files = [EX.MET_FASTQC_FILTER_TXT_R1,
        EX.MET_FASTQC_FILTER_TXT_R2]
    output:
        json_files = [EX.MET_FASTQC_FILTER_SUMMARY_R1,
        EX.MET_FASTQC_FILTER_SUMMARY_R2]
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.benchmark.txt"
    threads:
        1
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
