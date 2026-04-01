"""
Creates reference .fai file
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule samtools_index_files:
    input:
        reference = config["sci_params"]["reference_files"]["genome"]
    output:
        fai = config["sci_params"]["reference_files"]["genome"] + ".fai"
    log:
        L.SAMTOOLS_INDEX_FILES
    benchmark:
        B.SAMTOOLS_INDEX_FILES
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create index file
        samtools faidx {input.reference} 2>> {log}
        """