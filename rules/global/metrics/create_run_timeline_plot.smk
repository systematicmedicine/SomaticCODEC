"""
Creates a plot of jobs and resource usage during the run
"""

rule create_run_timeline_plot:
    input:
        job_log = "logs/global_rules/job_log.csv",
        resources_log = "logs/global_rules/system_resource_usage.csv",
        git_metadata = "logs/global_rules/git_metadata.json"
    output:
        plot = "logs/global_rules/run_timeline.pdf"
    params:
        run_name = config["run_name"],
        max_iops = config["infrastructure"]["disk"]["iops"],
        max_throughput = config["infrastructure"]["disk"]["throughput"]
    log:
        "logs/global_rules/create_run_timeline_plot.log"
    benchmark:
        "logs/global_rules/create_run_timeline_plot.benchmark.txt"
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
