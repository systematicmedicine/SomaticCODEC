# Creates a CSV of job start and finish times

rule create_job_log:
    input:
        component_metrics_csv = "metrics/component_metrics_report.csv",
        component_metrics_png = "metrics/component_metrics_heatmap.png",
        system_metrics_csv = "results/system_metrics_report.csv",
        system_metrics_png = "results/system_metrics_heatmap.png",
        log = ancient("logs/bin_scripts/run_pipeline.log")
    output:
        csv = "logs/global_rules/job_log.csv"
    log:
        "logs/global_rules/create_job_log.log"
    benchmark:
        "logs/global_rules/create_job_log.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "create_job_log.py")