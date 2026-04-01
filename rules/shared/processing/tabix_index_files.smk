"""
Creates index files for input VCFs
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule tabix_index_files:
    input:
        germline_vcf = config["sci_params"]["reference_files"]["germline_variants"]
    output:
        germline_tbi = config["sci_params"]["reference_files"]["germline_variants"] + ".tbi"
    log:
        L.TABIX_INDEX_FILES
    benchmark:
        B.TABIX_INDEX_FILES
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create index file
        tabix -p vcf {input.germline_vcf} 2>> {log}
        """