"""
--- paths.io.shared ---

Defines path constants for shared rules

Abbreviations:
    - INT (Intermediate file)
    - MET (Metrics file)

Authors: 
    - Cameron Fraser
    - Joshua Johnstone

"""

# ---------------------------------------------------------------------------------------------------------------
# Core pipeline
# ---------------------------------------------------------------------------------------------------------------

EXCLUDED_CHROMS_BED = "tmp/downloads/excluded_chromosomes.bed"
INCLUDED_CHROMS_BED = "tmp/downloads/included_chromosomes.bed"

# ---------------------------------------------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------------------------------------------

MET_COMPONENT_METRICS_REPORT = "metrics/component_metrics_report.csv"
MET_COMPONENT_METRICS_HEATMAP = "metrics/component_metrics_heatmap.png"

MET_SYSTEM_METRICS_REPORT = "results/system_metrics_report.csv"
MET_SYSTEM_METRICS_HEATMAP = "results/system_metrics_heatmap.png"
