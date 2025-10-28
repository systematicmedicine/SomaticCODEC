# Creates a CSV of job start and finish times

rule create_job_log:
    input:
        metrics_report_csv = "metrics/metrics_report.csv",
        metrics_report_heatmap = "metrics/metrics_heatmap.png",
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