# Logs disk space, memory, and cpu load at a defined interval

rule log_system_resource_usage:
    output:
        log = "logs/global_rules/system_resource_usage.csv",
        done_file = "logs/global_rules/log_system_resource_usage.done"
    params:
        sleep_interval = config["infrastructure"]["log_system_resource_usage"]["sleep_interval"],
        total_cores = int(os.popen("nproc").read().strip()) - config["infrastructure"]["threads"]["global_buffer"]
    log:
        "logs/global_rules/log_system_resource_usage.log"
    benchmark:
        "logs/global_rules/log_system_resource_usage.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        export SLEEP_INTERVAL={params.sleep_interval}
        export TOTAL_CORES={params.total_cores}
        
        bash scripts/monitor_system_resources.sh &

        touch {output.done_file}
        """