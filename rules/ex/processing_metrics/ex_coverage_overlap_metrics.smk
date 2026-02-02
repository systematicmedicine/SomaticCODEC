"""
Calculates overlap between coverage of various BED and BAM files
"""

import helpers.get_metadata as md

rule ex_coverage_overlap_metrics:
    input:
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["global"]["precomputed_masks"]),
        ex_dsc_bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        ex_dsc_bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed",
        ms_bam = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_deduped_map.bam"
        ),
        lowdepth_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_lowdepth.bed"
        ),
        germ_risk_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_ms_germ_risk.bed"
        ),
        combined_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_combined_mask.bed"
        ),
        ref_fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        output_json = "metrics/{ex_sample}/{ex_sample}_coverage_overlap_metrics.json"
    params: 
        ms_depth_threshold = config["sci_params"]["ms_low_depth_mask"]["min_depth"],
        ex_depth_threshold = 1,
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