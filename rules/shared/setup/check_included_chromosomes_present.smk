"""
Checks that chromosomes included for variant calling are present in reference and precomputed BEDs
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule check_included_chromosomes_present:
    input:
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai",
        precomputed_masks = config["sci_params"]["shared"]["precomputed_masks"]
    output:
        done_file = L.CHECK_INCLUDED_CHROMOSOMES_PRESENT_DONE
    params:
        included_chromosomes = config["sci_params"]["shared"]["included_chromosomes"]
    log:
        L.CHECK_INCLUDED_CHROMOSOMES_PRESENT
    benchmark:
        B.CHECK_INCLUDED_CHROMOSOMES_PRESENT
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Check included chromosomes present
        check_included_chromosomes_present.py \
            --fai {input.fai} \
            --precomputed_masks {input.precomputed_masks} \
            --included_chromosomes {params.included_chromosomes} \
            --done_file {output.done_file} \
            --log {log} 2>> {log}
        """
