"""
Generates a summary file with demuxed adaptor counts and Gini coefficient for inequality between adaptors
"""

import json

rule ex_demux_counts_and_gini:
    input:
        demux_metrics = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"
    output:
        demux_gini = "metrics/{ex_lane}/{ex_lane}_demux_counts_and_gini.json"
    params:
        ex_sample_ids = md.get_ex_sample_ids(config)
    log:
        "logs/{ex_lane}/ex_demux_counts_and_gini.log"
    benchmark:
        "logs/{ex_lane}/ex_demux_counts_and_gini.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate adapter counts and Gini coefficient
        ex_demux_counts_and_gini.py \
            --demux_metrics {input.demux_metrics} \
            --demux_gini {output.demux_gini} \
            --ex_sample_ids {params.ex_sample_ids} \
            --log {log} 2>> {log}
        """
