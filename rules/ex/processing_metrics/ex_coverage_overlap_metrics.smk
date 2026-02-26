"""
Calculates overlap between coverage of various BED and BAM files
"""

import helpers.get_metadata as md
from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS

rule ex_coverage_overlap_metrics:
    input:
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["shared"]["precomputed_masks"]),
        ex_dsc_bam = EX.FILTERED_DSC,
        ex_dsc_bai = EX.FILTERED_DSC_INDEX,
        include_bed = MS.INCLUDE_BED,
        ms_bam = lambda wc: MS.DEDUPED_BAM.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
            ),
        lowdepth_bed = lambda wc: MS.LOW_DEPTH_MASK.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
            ),
        germ_risk_bed = lambda wc: MS.GERMLINE_RISK_MASK.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
            ),
        combined_bed = lambda wc: MS.COMBINED_MASK.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
            ),
        ref_fai = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        output_json = EX.MET_COVERAGE_OVERLAP
    params: 
        ms_depth_threshold = config["sci_params"]["ms_low_depth_mask"]["min_depth"],
        ex_depth_threshold = config["sci_params"]["ex_dsc_coverage_metrics"]["ex_depth_threshold"],
        ms_bq_threshold = config["sci_params"]["ms_germline_risk"]["min_base_qual"],
        ex_bq_threshold = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]
    log:
        "logs/{ex_sample}/ex_coverage_overlap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_coverage_overlap_metrics.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate DSC coverage metrics
        ex_coverage_overlap_metrics.py \
            --threads {threads} \
            --precomputed_masks {input.precomputed_masks} \
            --ex_dsc_bam {input.ex_dsc_bam} \
            --include_bed {input.include_bed} \
            --ms_bam {input.ms_bam} \
            --lowdepth_bed {input.lowdepth_bed} \
            --germ_risk_bed {input.germ_risk_bed} \
            --combined_bed {input.combined_bed} \
            --ref_fai {input.ref_fai} \
            --output_json {output.output_json} \
            --ms_depth_threshold {params.ms_depth_threshold} \
            --ex_depth_threshold {params.ex_depth_threshold} \
            --ms_bq_threshold {params.ms_bq_threshold} \
            --ex_bq_threshold {params.ex_bq_threshold} \
            --log {log} 2>> {log}
        """