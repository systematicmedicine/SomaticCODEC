"""
Creates a mask for genomic positions with low read depth in matched sample
    - This is the inverse of the positions with depth >= min_depth in the MS pileup
"""

from definitions.paths.io import ms as MS

rule ms_low_depth:
    input:
        pileup_depth_vcf = MS.PILEUP_DEPTH,
        ref_fai = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        intermediate_bed = temp(MS.LOW_DEPTH_MASK_INT1),
        lowdepth_bed = temp(MS.LOW_DEPTH_MASK)
    log:
        "logs/{ms_sample}/ms_low_depth.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Convert VCF file to BED
        vcf2bed --do-not-sort < {input.pileup_depth_vcf} > {output.intermediate_bed} 2>> {log}

        # Invert positions with depth to obtain low depth BED
        bedtools complement -i {output.intermediate_bed} -g {input.ref_fai} > {output.lowdepth_bed} 2>> {log}
        """