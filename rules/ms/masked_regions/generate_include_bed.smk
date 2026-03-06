"""
Generates a BED file of regions eligible for variant calling
    - Inverse of combined mask
"""
import helpers.get_metadata as md
from definitions.paths.io import ms as MS
from definitions.paths import log as L

# Main rule
rule generate_include_bed:
    input:
        ms_samples = config["metadata"]["ms_samples_metadata"],
        mask_bed = lambda wc: MS.COMBINED_MASK.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
        ),
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        include_bed = MS.INCLUDE_BED
    log:
        L.GENERATE_INCLUDE_BED
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