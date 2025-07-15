"""
--- other_metrics.smk ---

Rules for creating metrics files that are not part of ex or ms pipelines

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

# Generates a pass/fail report for all component level metrics
rule component_metrics_report:
    input:
        final_ms_metrics_file = expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.txt", ms_sample = ms_samples["ms_sample"].tolist()),
        final_ex_metrics_file = expand("metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.txt", ex_sample = ex_samples["ex_sample"].tolist())
    output:
        report = "metrics/component_metrics_report.csv"
    log:
        "logs/component_metrics_report.log"
    benchmark:
        "logs/component_metrics_report.benchmark.txt"
    script:
        "../scripts/component_metrics_report.R"

rule collate_benchmarks:
    input:
        final_rule_output = "metrics/component_metrics_report.csv"
    output:
        file_path = "logs/combined_benchmarks.log"
    script:
        "../scripts/collate_benchmarks.py"