"""
Calulcates the number of bases at each depth level
"""

from definitions.paths.io import ms as MS

rule ms_depth_histogram_metrics:
    input:
        bam = MS.DEDUPED_BAM,
        bai = MS.DEDUPED_BAM_INDEX
    output:
        depth_histogram = MS.MET_DEPTH,
        intermediate_depth_per_base = temp(MS.MET_DEPTH_INT1),
        intermediate_depth_values = temp(MS.MET_DEPTH_INT2),
        intermediate_depth_values_sorted = temp(MS.MET_DEPTH_INT3)
    params:
        min_base_qual = config["sci_params"]["ms_pileup"]["min_base_qual"],
        min_map_qual = config["sci_params"]["ms_pileup"]["min_map_qual"],
    log:
        "logs/{ms_sample}/ms_depth_histogram_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_depth_histogram_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Calculate depth per base
        samtools depth \
        -aa \
        --min-BQ {params.min_base_qual} \
        --min-MQ {params.min_map_qual} \
        -s \
        -J \
        {input.bam} > {output.intermediate_depth_per_base} 2>> {log}

        # Extract depth column
        awk '{{print $3}}' {output.intermediate_depth_per_base} > {output.intermediate_depth_values} 2>> {log}

        # Sort numerically
        sort -n {output.intermediate_depth_values} > {output.intermediate_depth_values_sorted} 2>> {log}

        # Generate counts for each depth value
        uniq -c {output.intermediate_depth_values_sorted} > {output.depth_histogram} 2>> {log}
        """