"""
Calculates DSC coverage metrics
"""

from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_dsc_coverage_metrics:
    input:
        bam_ex_dsc = EX.FILTERED_DSC,
        bai_ex_dsc = EX.FILTERED_DSC_INDEX,
        include_bed = MS.INCLUDE_BED,
        ref_fai = config["sci_params"]["reference_files"]["genome"] + ".fai"
    output:
        json = EX.MET_DSC_COVERAGE_JSON,
        plot = EX.MET_DSC_COVERAGE_PLOT
    params: 
        ex_depth_threshold = config["sci_params"]["ex_dsc_coverage_metrics"]["ex_depth_threshold"],
        ex_bq_threshold = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]
    log:
        L.EX_DSC_COVERAGE_METRICS
    benchmark:
        B.EX_DSC_COVERAGE_METRICS
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate DSC coverage metrics
        ex_dsc_coverage_metrics.py \
            --threads {threads} \
            --ex_dsc_bam {input.bam_ex_dsc} \
            --include_bed {input.include_bed} \
            --ref_fai {input.ref_fai} \
            --output_json {output.json} \
            --output_plot {output.plot} \
            --ex_depth_threshold {params.ex_depth_threshold} \
            --ex_bq_threshold {params.ex_bq_threshold} \
            --log {log} 2>> {log}
        """