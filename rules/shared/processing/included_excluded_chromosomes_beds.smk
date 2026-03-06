"""
Creates a mask for chromosomes that will be excluded for variant calling 
e.g. chrUn, chr*_random, chrM, chrEBV
"""

from definitions.paths.io import shared as S
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule included_excluded_chromosomes_beds:
    input:
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai",
    output:
        exclude_bed = temp(S.EXCLUDED_CHROMS_BED),
        include_bed = temp(S.INCLUDED_CHROMS_BED)
    params:
        included_chromosomes = config["sci_params"]["shared"]["included_chromosomes"]
    log:
        L.INCLUDED_EXCLUDED_CHROMOSOMES_BEDS
    benchmark:
        B.INCLUDED_EXCLUDED_CHROMOSOMES_BEDS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create masks for included and excluded chromosomes
        included_excluded_chromosomes_beds.py \
            --fai {input.fai} \
            --exclude_bed {output.exclude_bed} \
            --include_bed {output.include_bed} \
            --included_chromosomes {params.included_chromosomes} \
            --log {log} 2>> {log}
        """
