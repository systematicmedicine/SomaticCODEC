"""
Generates a summary of key metrics for ms fastqc reports
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_fastqc_summary_metrics:
    input:
        fastqc_files = [MS.MET_FASTQC_RAW_TXT_R1,
        MS.MET_FASTQC_RAW_TXT_R2,
        MS.MET_FASTQC_FILTER_TXT_R1,
        MS.MET_FASTQC_FILTER_TXT_R2]
    output:
        json_files = [MS.MET_FASTQC_RAW_SUMMARY_R1,
        MS.MET_FASTQC_RAW_SUMMARY_R2,
        MS.MET_FASTQC_FILTER_SUMMARY_R1,
        MS.MET_FASTQC_FILTER_SUMMARY_R2]
    params:
        sample = "{ms_sample}"
    log:
        L.MS_FASTQC_SUMMARY_METRICS
    benchmark:
        B.MS_FASTQC_SUMMARY_METRICS
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