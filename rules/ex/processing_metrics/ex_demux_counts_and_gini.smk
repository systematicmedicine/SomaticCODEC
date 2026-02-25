"""
Generates a summary file with demuxed adaptor counts and Gini coefficient for inequality between adaptors
"""

import json
from definitions.paths.io import ex as EX

rule ex_demux_counts_and_gini:
    input:
        demux_metrics = EX.MET_DEMULIPLEX_FASTQ
    output:
        demux_gini = EX.MET_DEMUX_COUNTS_GINI
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
