"""
Generates a summary of genome coverage by depth
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_coverage_by_depth_metrics:
    input:
        depth_histogram = MS.MET_DEPTH
    output:
        coverage_by_depth = MS.MET_COVERAGE
    params:
        sample = "{ms_sample}",
        min_depth = config["sci_params"]["ms_pileup"]["min_depth"]
    log:
        L.MS_COVERAGE_BY_DEPTH_METRICS
    benchmark:
        B.MS_COVERAGE_BY_DEPTH_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate coverage by depth metrics
        ms_coverage_by_depth_metrics.py \
            --depth_histogram {input.depth_histogram} \
            --coverage_by_depth {output.coverage_by_depth} \
            --min_depth {params.min_depth} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
