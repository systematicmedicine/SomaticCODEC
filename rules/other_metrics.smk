"""
--- other_metrics.smk ---

Rules for creating metrics files that are not part of ex or ms pipelines

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import helpers.get_metadata as md

# Write git metadata to file for version tracking
rule write_git_metadata:
    output:
        file_path = "logs/global_rules/git_metadata.json"
    log:
        "logs/global_rules/write_git_metadata.log"
    benchmark:
        "logs/global_rules/write_git_metadata.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        "../scripts/write_git_metadata.py"


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
        "../scripts/metrics_report.R"


# Creates a CSV of job start and finish times
rule create_job_log:
    input:
        rules.create_metrics_report.output,
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
        "../scripts/create_job_log.py"


# Creates a plot of jobs and resource usage during the run
rule create_run_timeline_plot:
    input:
        job_log = "logs/global_rules/job_log.csv",
        resources_log = "logs/global_rules/system_resource_usage.csv",
        git_metadata = "logs/global_rules/git_metadata.json"
    output:
        plot = "logs/global_rules/run_timeline.pdf"
    params:
        run_name = config["run_name"],
        max_iops = config["infrastructure"]["disk"]["iops"]
    log:
        "logs/global_rules/create_run_timeline_plot.log"
    benchmark:
        "logs/global_rules/create_run_timeline_plot.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        "../scripts/create_run_timeline_plot.R"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        rules.write_git_metadata.output.file_path,
        rules.create_run_timeline_plot.output
    output:
        file_path = "logs/global_rules/combined_benchmarks.csv"
    log:
        "logs/global_rules/collate_benchmarks.log"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        "../scripts/collate_benchmarks.py"