"""
Creates a CSV of job start and finish times
"""

rule create_job_log:
    input:
        component_metrics_csv = "metrics/component_metrics_report.csv",
        component_metrics_png = "metrics/component_metrics_heatmap.png",
        system_metrics_csv = "results/system_metrics_report.csv",
        system_metrics_png = "results/system_metrics_heatmap.png",
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
