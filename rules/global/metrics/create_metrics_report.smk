"""
Generates a pass/fail report for component & system level metrics
"""

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "outputs", "pipeline_outputs.smk")

from definitions.paths.io import shared as S

# Rule
rule create_metrics_report:
    input:
        component_metrics_metadata = config["metadata"]["component_metrics_metadata"],
        system_metrics_metadata = config["metadata"]["system_metrics_metadata"],
        ms_processing_metrics =  ms_processing_metrics,
        ex_processing_metrics = ex_processing_metrics,
        ex_variant_analysis = ex_variant_analysis
    output:
        component_csv = S.MET_COMPONENT_METRICS_REPORT,
        component_png = S.MET_COMPONENT_METRICS_HEATMAP,
        system_csv = S.MET_SYSTEM_METRICS_REPORT,
        system_png = S.MET_SYSTEM_METRICS_HEATMAP
    params:
        run_name = config["run_name"]
    log:
        "logs/global_rules/create_metrics_report.log"
    benchmark:
        "logs/global_rules/create_metrics_report.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create metrics report
        metrics_report.R \
            --component_metrics_metadata {input.component_metrics_metadata} \
            --system_metrics_metadata {input.system_metrics_metadata} \
            --component_csv {output.component_csv} \
            --component_png {output.component_png} \
            --system_csv {output.system_csv} \
            --system_png {output.system_png} \
            --run_name {params.run_name} \
            --log {log} 2>> {log}
        """
