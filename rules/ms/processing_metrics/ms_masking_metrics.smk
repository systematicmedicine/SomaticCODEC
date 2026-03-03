"""
Generates metrics for each mask BED file
"""

from definitions.paths.io import ms as MS
import helpers.get_metadata as md

rule ms_masking_metrics:
    input:
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["shared"]["precomputed_masks"]),
        ms_lowdepth_bed = MS.LOW_DEPTH_MASK,
        ms_germ_risk_bed = MS.GERMLINE_RISK_MASK,
        all_ms_germ_risk_beds = expand(MS.GERMLINE_RISK_MASK, ms_sample = md.get_ms_sample_ids(config)),
        combined_bed = MS.COMBINED_MASK,
        ref_index = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        mask_metrics = MS.MET_MASKING,
        int_germ_risk_all_samples = temp(MS.MET_MASKING_INT1),
        int_sorted = temp(MS.MET_MASKING_INT2),
        int_merged = temp(MS.MET_MASKING_INT3)
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_masking_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_masking_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Combine all germ risk BEDs into one combined BED
        cat {input.all_ms_germ_risk_beds} > {output.int_germ_risk_all_samples} 2>> {log}
        
        # Generate mask metrics
        ms_masking_metrics.py \
            --precomputed_masks {input.precomputed_masks} \
            --ms_lowdepth_bed {input.ms_lowdepth_bed} \
            --ms_germ_risk_bed {input.ms_germ_risk_bed} \
            --ms_germ_risk_all_samples {output.int_germ_risk_all_samples} \
            --combined_bed {input.combined_bed} \
            --ref_index {input.ref_index} \
            --mask_metrics {output.mask_metrics} \
            --intermediate_sorted {output.int_sorted} \
            --intermediate_merged {output.int_merged} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
