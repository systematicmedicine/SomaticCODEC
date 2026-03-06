"""
Logs disk space, memory, and cpu load at a defined interval
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule log_system_resource_usage:
    output:
        log = L.SYSTEM_RESOURCE_USAGE,
        done_file = L.LOG_SYSTEM_RESOURCE_USAGE_DONE
    params:
        sleep_interval = config["infrastructure"]["log_system_resource_usage"]["sleep_interval"],
        total_cores = int(os.popen("nproc").read().strip()) - config["infrastructure"]["threads"]["global_buffer"]
    log:
        L.LOG_SYSTEM_RESOURCE_USAGE
    benchmark:
        B.LOG_SYSTEM_RESOURCE_USAGE
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Define parameters
        export SLEEP_INTERVAL={params.sleep_interval}
        export TOTAL_CORES={params.total_cores}
        
        # Log system resources in background
        log_system_resource_usage.sh &

        # Create done file
        touch {output.done_file} 2>> {log}
        """