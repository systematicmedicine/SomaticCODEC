"""
Creates a CSV of job start and finish times
"""

from definitions.paths.io import shared as S

rule create_job_log:
    input:
        component_metrics_csv = S.MET_COMPONENT_METRICS_REPORT,
        component_metrics_png = S.MET_COMPONENT_METRICS_HEATMAP,
        system_metrics_csv = S.MET_SYSTEM_METRICS_REPORT,
        system_metrics_png = S.MET_SYSTEM_METRICS_HEATMAP,
        run_pipeline_log = ancient("logs/bin_scripts/run_pipeline.log")
    output:
        job_log_csv = "logs/global_rules/job_log.csv"
    log:
        "logs/global_rules/create_job_log.log"
    benchmark:
        "logs/global_rules/create_job_log.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create job log
        create_job_log.py \
            --run_pipeline_log {input.run_pipeline_log} \
            --job_log_csv {output.job_log_csv} \
            --log {log} 2>> {log}
        """
