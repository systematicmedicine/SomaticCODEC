"""
Calulcates the number of bases at each depth level
"""

rule ms_depth_histogram_metrics:
    input:
        intermediate_depth_per_base = "tmp/{ms_sample}/{ms_sample}_depth_per_base.txt",
    output:
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt",
        intermediate_depth_values = temp("tmp/{ms_sample}/{ms_sample}_depth_values.txt"),
        intermediate_depth_values_sorted = temp("tmp/{ms_sample}/{ms_sample}_depth_values_sorted.txt")
    params:
        threshold = config["sci_params"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_low_depth_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth_mask.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Extract depth column
        awk '{{print $3}}' {input.intermediate_depth_per_base} > {output.intermediate_depth_values} 2>> {log}

        # Sort numerically
        sort -n {output.intermediate_depth_values} > {output.intermediate_depth_values_sorted} 2>> {log}

        # Generate counts for each depth value
        uniq -c {output.intermediate_depth_values_sorted} > {output.depth_histogram} 2>> {log}
        """