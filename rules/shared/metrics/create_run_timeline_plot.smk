"""
Creates a plot of jobs and resource usage during the run
"""

from definitions.paths import log as L

rule create_run_timeline_plot:
    input:
        job_log = L.JOB_LOG,
        resources_log = L.SYSTEM_RESOURCE_USAGE
    output:
        plot = L.RUN_TIMELINE
    params:
        run_name = config["run_name"],
        max_iops = config["infrastructure"]["disk"]["iops"],
        max_throughput = config["infrastructure"]["disk"]["throughput"]
    log:
        L.CREATE_RUN_TIMELINE_PLOT
    benchmark:
        "logs/shared_rules/create_run_timeline_plot.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create run timeline plot
        create_run_timeline_plot.R \
            --job_log {input.job_log} \
            --resources_log {input.resources_log} \
            --plot {output.plot} \
            --run_name {params.run_name} \
            --max_iops {params.max_iops} \
            --max_throughput {params.max_throughput} \
            --log {log} 2>> {log}
        """
