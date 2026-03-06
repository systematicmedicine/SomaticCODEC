"""
Ensures that run_pipeline.log has been created
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ensure_pipeline_log_exists:
    output:
        log = L.RUN_PIPELINE
    log:
        L.ENSURE_PIPELINE_LOG_EXISTS
    benchmark:
        B.ENSURE_PIPELINE_LOG_EXISTS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create pipeline log file
        touch {output.log} 2>> {log}
        """