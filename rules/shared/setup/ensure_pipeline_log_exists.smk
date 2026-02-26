"""
Ensures that run_pipeline.log has been created
"""

rule ensure_pipeline_log_exists:
    output:
        log = "logs/bin_scripts/run_pipeline.log"
    log:
        "logs/shared_rules/ensure_pipeline_log_exists.log"
    benchmark:
        "logs/shared_rules/ensure_pipeline_log_exists.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create pipeline log file
        touch {output.log}
        """