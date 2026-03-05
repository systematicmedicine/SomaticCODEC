"""
Logs disk space, memory, and cpu load at a defined interval
"""

import definitions.paths.log as L

rule log_system_resource_usage:
    output:
        log = "logs/shared_rules/system_resource_usage.csv",
        done_file = L.SYS_RESOURCE_LOG_DONE
    params:
        sleep_interval = config["infrastructure"]["log_system_resource_usage"]["sleep_interval"],
        total_cores = int(os.popen("nproc").read().strip()) - config["infrastructure"]["threads"]["global_buffer"]
    log:
        "logs/shared_rules/log_system_resource_usage.log"
    benchmark:
        "logs/shared_rules/log_system_resource_usage.benchmark.txt"
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