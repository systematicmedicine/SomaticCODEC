# Generates metrics for each mask BED file

rule ms_masking_metrics:
    input:
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["global"]["precomputed_masks"]),
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        combined_bed = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed",
        ref_index = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        mask_metrics = "metrics/{ms_sample}/{ms_sample}_mask_metrics.json",
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.txt"),
        intermediate_merged = temp("tmp/{ms_sample}/{ms_sample}_masks_merged.txt")
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_masking_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_masking_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate mask metrics
        ms_masking_metrics.py \
            --precomputed_masks {input.precomputed_masks} \
            --ms_lowdepth_bed {input.ms_lowdepth_bed} \
            --ms_germ_del_bed {input.ms_germ_del_bed} \
            --ms_germ_ins_bed {input.ms_germ_ins_bed} \
            --ms_germ_snv_bed {input.ms_germ_snv_bed} \
            --combined_bed {input.combined_bed} \
            --ref_index {input.ref_index} \
            --mask_metrics {output.mask_metrics} \
            --intermediate_sorted {output.intermediate_sorted} \
            --intermediate_merged {output.intermediate_merged} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
