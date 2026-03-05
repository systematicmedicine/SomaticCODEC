"""
Generates a pass/fail report for component & system level metrics
"""

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "outputs", "pipeline_outputs.smk")

from definitions.paths.io import shared as S
from helpers import get_metadata as md
from definitions.paths import log as L

# Rule
rule create_metrics_report:
    input:
        # Metrics metadata
        component_metrics_metadata = config["metadata"]["component_metrics_metadata"],
        system_metrics_metadata = config["metadata"]["system_metrics_metadata"],

        # Metrics files
        ms_processing_metrics =  ms_processing_metrics,
        ex_processing_metrics = ex_processing_metrics,
        ex_variant_analysis = ex_variant_analysis,

        # Sample metadata
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"],
        ms_samples = config["metadata"]["ms_samples_metadata"]
    output:
        component_csv = S.MET_COMPONENT_METRICS_REPORT,
        component_png = S.MET_COMPONENT_METRICS_HEATMAP,
        system_csv = S.MET_SYSTEM_METRICS_REPORT,
        system_png = S.MET_SYSTEM_METRICS_HEATMAP
    params:
        ex_lanes = md.get_ex_lane_ids(config),
        ex_samples = md.get_ex_sample_ids(config),
        ms_samples = md.get_ms_sample_ids(config),
        run_name = config["run_name"]
    log:
        L.CREATE_METRICS_REPORT
    benchmark:
        "logs/shared_rules/create_metrics_report.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create metrics report
        create_metrics_report.R \
            --component_metrics_metadata {input.component_metrics_metadata} \
            --system_metrics_metadata {input.system_metrics_metadata} \
            --component_csv {output.component_csv} \
            --component_png {output.component_png} \
            --system_csv {output.system_csv} \
            --system_png {output.system_png} \
            --ex_lanes {params.ex_lanes} \
            --ex_samples {params.ex_samples} \
            --ms_samples {params.ms_samples} \
            --run_name {params.run_name} \
            --log {log} 2>> {log}
        """
