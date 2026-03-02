"""
Calulcates the number of bases at each depth level
"""

from definitions.paths.io import ms as MS

rule ms_depth_histogram_metrics:
    input:
        intermediate_depth_per_base = MS.LOW_DEPTH_MASK_INT1,
    output:
        depth_histogram = MS.MET_DEPTH_HIST,
        intermediate_depth_values = temp(MS.MET_DEPTH_HIST_INT1),
        intermediate_depth_values_sorted = temp(MS.MET_DEPTH_HIST_INT2)
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