"""
--- other_metrics.smk ---

Rules for creating metrics files that are not part of ex or ms pipelines

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import scripts.get_metadata as md


# Write git metadata to file for version tracking
rule write_git_metadata:
    output:
        file_path = "logs/git_metadata.json"
    benchmark:
        "logs/write_git_metadata.benchmark.txt"
    script:
        "../scripts/write_git_metadata.py"


# Generates a pass/fail report for component & system level metrics
rule create_metrics_report:
    input:
        component_metrics_metadata = config["component_metrics_path"],
        system_metrics_metadata = config["system_metrics_path"],
        ms_metrics = ms_metrics,
        ex_metrics = ex_metrics
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    log:
        "logs/create_metrics_report.log"
    benchmark:
        "logs/create_metrics_report.benchmark.txt"
    script:
        "../scripts/metrics_report.R"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        rules.write_git_metadata.output.file_path,
        rules.create_metrics_report.output
    output:
        file_path = "logs/combined_benchmarks.csv"
    log:
        "logs/collate_benchmarks.log"
    script:
        "../scripts/collate_benchmarks.py"