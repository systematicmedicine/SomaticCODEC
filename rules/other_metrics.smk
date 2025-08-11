"""
--- other_metrics.smk ---

Rules for creating metrics files that are not part of ex or ms pipelines

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

import scripts.get_metadata as md

# Generates a pass/fail report for component & system level metrics
rule create_metrics_report:
    input:
        component_metrics_metadata = config["component_metrics_path"],
        system_metrics_metadata = config["system_metrics_path"],
        final_ms_metrics_file = expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.json", ms_sample = md.get_ms_sample_ids(config)),
        final_ex_metrics_file = expand("metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.txt", ex_sample = md.get_ex_sample_ids(config))
    output:
        csv_path = "metrics/metrics_report.csv",
        heatmap_path = "metrics/metrics_heatmap.png"
    log:
        "logs/create_metrics_report.log"
    benchmark:
        "logs/create_metrics_report.benchmark.txt"
    script:
        "../scripts/metrics_report.R"


# Write git metadata to file for version tracking
rule write_git_metadata:
    output:
        file_path = "logs/git_metadata.json"
    benchmark:
        "logs/write_git_metadata.benchmark.txt"
    script:
        "../scripts/write_git_metadata.py"


# Collates all benchmarks into a single CSV
rule collate_benchmarks:
    input:
        final_output_1 = "logs/git_metadata.json",
        final_output_2 = "metrics/metrics_report.csv",
        final_ms_metrics_file = expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.json", ms_sample = md.get_ms_sample_ids(config)),
        final_ex_metrics_file = expand("metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.txt", ex_sample = md.get_ex_sample_ids(config))
    output:
        file_path = "logs/combined_benchmarks.csv"
    log:
        "logs/collate_benchmarks.log"
    script:
        "../scripts/collate_benchmarks.py"