# Generates a pass/fail report for component & system level metrics

rule create_metrics_report:
    input:
        component_metrics_metadata = config["metadata"]["component_metrics_metadata"],
        system_metrics_metadata = config["metadata"]["system_metrics_metadata"],
        version_metadata = "logs/global_rules/git_metadata.json",
        ms_metrics = ms_metrics,
        ex_metrics = ex_metrics
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    params:
        run_name = config["run_name"]
    log:
        "logs/global_rules/create_metrics_report.log"
    benchmark:
        "logs/global_rules/create_metrics_report.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "metrics_report.R")