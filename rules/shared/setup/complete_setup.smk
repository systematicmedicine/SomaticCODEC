"""
Ensures that setup has been completed
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule complete_setup:
    input:
        run_pipeline_log = L.RUN_PIPELINE,
        sys_resource_log_done = L.LOG_SYSTEM_RESOURCE_USAGE_DONE,
        inc_chrom_present_done = L.CHECK_INCLUDED_CHROMOSOMES_PRESENT_DONE
    output:
        L.SETUP_DONE
    log:
        L.COMPLETE_SETUP
    benchmark:
        B.COMPLETE_SETUP
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create setup complete done file
        touch {output} 2>> {log}
        """