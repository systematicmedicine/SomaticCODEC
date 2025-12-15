"""
Combines all masks into a single BED file
"""

rule combine_masks:
    input:
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["global"]["precomputed_masks"]),
        excluded_chromosomes_bed = "tmp/downloads/excluded_chromosomes.bed",
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_risk_bed = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.bed",
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai" 
    output:
        combined_bed = temp("tmp/{ms_sample}/{ms_sample}_combined_mask.bed"),
        intermediate_cat = temp("tmp/{ms_sample}/{ms_sample}_masks_cat.bed"),
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.bed")
    log:
        "logs/{ms_sample}/combine_masks.log"
    benchmark:
        "logs/{ms_sample}/combine_masks.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Combine masks
        cat {input.precomputed_masks} \
        {input.excluded_chromosomes_bed} \
        {input.ms_lowdepth_bed} \
        {input.ms_germ_risk_bed} > {output.intermediate_cat} 2>> {log}

        # Sort combined BED in the same order as the reference file       
        bedtools sort -faidx {input.fai} -i {output.intermediate_cat} > {output.intermediate_sorted} 2>> {log}

        # Merge overlapping regions in combined BED
        bedtools merge -i {output.intermediate_sorted} > {output.combined_bed} 2>> {log}
        """