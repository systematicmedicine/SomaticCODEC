"""
--- component_metrics.smk ---

Rules for collating component level metrics, from multiple metrics files generated elsewhere.

Authors:
    - Joshua Johnstone
    - Cameron Fraser

"""

# Generates a pass/fail report for all component level metrics
rule component_metrics_report:
    output:
        report = "metrics/component_metrics_report.csv"
    script:
        "../scripts/component_metrics_report.R"