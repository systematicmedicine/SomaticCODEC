# Generates a summary of genome coverage by depth

rule ms_coverage_by_depth_metrics:
    input:
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt"
    output:
        coverage_by_depth = "metrics/{ms_sample}/{ms_sample}_coverage_by_depth.json"
    params:
        sample = "{ms_sample}",
        min_depth = config["sci_params"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_coverage_by_depth_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_coverage_by_depth_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ms_coverage_by_depth_metrics.py")