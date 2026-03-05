"""
Ensures that setup has been completed
"""

from definitions.paths import log as L

rule complete_setup:
    input:
        run_pipeline_log = L.RUN_PIPELINE,
        sys_resource_log_done = L.SYS_RESOURCE_LOG_DONE,
        inc_chrom_present_done = L.INC_CHROM_PRESENT_DONE
    output:
        L.SETUP_DONE
    log:
        L.COMPLETE_SETUP
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