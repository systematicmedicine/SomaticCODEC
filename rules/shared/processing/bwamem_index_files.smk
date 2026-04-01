"""
Creates index files from reference genome
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule bwamem_index_files:
    input:
        reference = config["sci_params"]["reference_files"]["genome"]
    output:
        amb = config["sci_params"]["reference_files"]["genome"] + ".amb",
        ann = config["sci_params"]["reference_files"]["genome"] + ".ann",
        bwt = config["sci_params"]["reference_files"]["genome"] + ".bwt.2bit.64",
        pac = config["sci_params"]["reference_files"]["genome"] + ".pac",
        sa = config["sci_params"]["reference_files"]["genome"] + ".0123"
    log:
        L.BWAMEM_INDEX_FILES
    benchmark:
        B.BWAMEM_INDEX_FILES
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create index files
        bwa-mem2 index {input.reference} 2>> {log}
        """