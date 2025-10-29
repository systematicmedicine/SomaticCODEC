# ====================================================================================
# 
#   create_metrics_report.smk
#
#   Generates a pass/fail report for component & system level metrics
#
#   Author: Cameron
#
# ====================================================================================

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "pipeline_outputs.smk")

# Rule
rule create_metrics_report:
    input:
        component_metrics_metadata = config["metadata"]["component_metrics_metadata"],
        system_metrics_metadata = config["metadata"]["system_metrics_metadata"],
        ms_processing_metrics =  ms_processing_metrics,
        ex_processing_metrics = ex_processing_metrics,
        ex_variant_analysis = ex_variant_analysis
    output:
        component_csv = "metrics/component_metrics_report.csv",
        component_png = "metrics/component_metrics_heatmap.png",
        system_csv = "results/system_metrics_report.csv",
        system_png = "results/system_metrics_heatmap.png"
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