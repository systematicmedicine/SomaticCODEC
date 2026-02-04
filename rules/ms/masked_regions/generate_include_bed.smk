"""
Generates a BED file of regions eligible for variant calling
    - Inverse of combined mask
"""
import helpers.get_metadata as md

rule generate_include_bed:
    input:
        ms_samples = config["metadata"]["ms_samples_metadata"],
        mask_bed = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_combined_mask.bed"
        ),
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    log:
        "logs/{ex_sample}/generate_include_bed.log"
    benchmark:
        "logs/{ex_sample}/generate_include_bed.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate include BED
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed} 2>> {log}
        """