"""
Generates adapter FASTA files for demultiplexing
"""

import helpers.get_metadata as md
import json

rule ex_generate_demux_adaptors:
    input:
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"],
        ex_technical_controls = config["metadata"]["ex_technical_controls_metadata"],
        ex_adapters = config["metadata"]["ex_adapters_metadata"]
    output:
        "tmp/{ex_lane}/{ex_lane}_{region}.fasta"
    wildcard_constraints:
        region="r1_start|r2_start"
    params:
        adapter_dict = json.dumps(md.get_ex_lane_adapter_dict(config))
    log:
        "logs/global_rules/ex_generate_demux_adaptors/{ex_lane}_{region}.log"
    benchmark:
        "logs/global_rules/ex_generate_demux_adaptors/{ex_lane}_{region}.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate adapter FASTA files
        ex_generate_demux_adaptors.py \
          --adapter_dict '{params.adapter_dict}' \
          --lane '{wildcards.ex_lane}' \
          --region '{wildcards.region}' \
          --output '{output}' \
          --log {log} 2>> {log}
        """