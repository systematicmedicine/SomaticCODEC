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
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/write_git_metadata.py"


# Generates a pass/fail report for component & system level metrics
rule create_metrics_report:
    input:
        component_metrics_metadata = config["files"]["component_metrics_metadata"],
        system_metrics_metadata = config["files"]["system_metrics_metadata"],
        ms_metrics = ms_metrics,
        ex_metrics = ex_metrics
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    log:
        "logs/global_rules/create_metrics_report.log"
    benchmark:
        "logs/global_rules/create_metrics_report.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/metrics_report.R"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        rules.write_git_metadata.output.file_path,
        rules.create_metrics_report.output
    output:
        file_path = "logs/global_rules/combined_benchmarks.csv"
    log:
        "logs/global_rules/collate_benchmarks.log"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/collate_benchmarks.py"


# Creates a CSV of job start and finish times
rule create_job_log:
    input:
        rules.collate_benchmarks.output,
        log = ancient("logs/bin_scripts/run_pipeline.log")
    output:
        csv = "logs/global_rules/job_log.csv"
    log:
        "logs/global_rules/create_job_log.log"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/create_job_log.py"
