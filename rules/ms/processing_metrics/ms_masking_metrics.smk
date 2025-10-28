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
    script:
        os.path.join(workflow.basedir, "scripts", "ms_masking_metrics.py")