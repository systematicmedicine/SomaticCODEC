"""
Creates index files from reference genome
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule bwamem_index_files:
    input:
        reference = config["sci_params"]["reference_files"]["genome"]["f"]
    output:
        amb = config["sci_params"]["reference_files"]["genome"]["f"] + ".amb",
        ann = config["sci_params"]["reference_files"]["genome"]["f"] + ".ann",
        bwt = config["sci_params"]["reference_files"]["genome"]["f"] + ".bwt.2bit.64",
        pac = config["sci_params"]["reference_files"]["genome"]["f"] + ".pac",
        sa = config["sci_params"]["reference_files"]["genome"]["f"] + ".0123"
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