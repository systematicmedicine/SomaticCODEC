"""
Ensures that setup has been completed
"""

import definitions.paths.log as L

rule complete_setup:
    input:
        run_pipeline_log = "logs/bin_scripts/run_pipeline.log",
        sys_resource_log_done = L.SYS_RESOURCE_LOG_DONE,
        inc_chrom_present_done = L.INC_CHROM_PRESENT_DONE
    output:
        L.SETUP_DONE
    log:
        "logs/shared_rules/complete_setup.log"
    benchmark:
        "logs/shared_rules/complete_setup.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create setup complete done file
        touch {output}
        """