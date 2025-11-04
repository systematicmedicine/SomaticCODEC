# Creates a plot of jobs and resource usage during the run

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
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "create_run_timeline_plot.R")