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
        config_json = json.dumps(config)        
    log:
        "logs/{ex_lane}/ex_demux_counts_and_gini.log"
    benchmark:
        "logs/{ex_lane}/ex_demux_counts_and_gini.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate adapter counts and Gini coefficient
        python {workflow.basedir}/scripts/ex_demux_counts_and_gini.py \
            --demux_metrics {input.demux_metrics} \
            --demux_gini {output.demux_gini} \
            --config '{params.config_json}' \
            --log {log} 2>> {log}
        """
