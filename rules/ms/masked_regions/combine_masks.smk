"""
Combines all masks into a single BED file
"""

import helpers.get_metadata as md
from definitions.paths.io import ms as MS
from definitions.paths.io import shared as S
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule combine_masks:
    input:
        # Precomputed masks as defined in config
        precomputed_masks = expand("{mask}", mask=config["sci_params"]["shared"]["precomputed_masks"]),
        
        # Excluded chromosomes (inverse of included chromosomes defined in config)
        excluded_chromosomes_bed = S.EXCLUDED_CHROMS_BED,

        # Positions with depth < min_depth threshold
        ms_lowdepth_bed = MS.LOW_DEPTH_MASK,

        # Germline variant risk sites
        ms_germ_risk_bed = MS.GERMLINE_RISK_MASK,

        # Reference FAI
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai" 
    output:
        combined_bed = temp(MS.COMBINED_MASK),
        intermediate_cat = temp(MS.COMBINE_MASKS_INT1),
        intermediate_sorted = temp(MS.COMBINE_MASKS_INT2)
    log:
        L.COMBINE_MASKS
    benchmark:
        B.COMBINE_MASKS
    threads:
        1
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