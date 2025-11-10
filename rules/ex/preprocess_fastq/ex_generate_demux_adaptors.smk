"""
Generates adapter FASTA files for demultiplexing
"""

import scripts.helpers.get_metadata as md
import json

rule ex_generate_demux_adaptors:
    input:
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"],
        ex_technical_controls = config["metadata"]["ex_technical_controls_metadata"],
        ex_adapters = config["metadata"]["ex_adapters_metadata"]
    output:
        adapter_fasta_outputs = expand(
            "tmp/{ex_lane}/{ex_lane}_{region}.fasta",
            ex_lane = md.get_ex_lane_ids(config),
            region = ["r1_start", "r1_end", "r2_start", "r2_end"]
        )
    params:
        config_json = json.dumps(config)
    log:
        "logs/global_rules/ex_generate_demux_adaptors.log"
    benchmark:
        "logs/global_rules/ex_generate_demux_adaptors.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate adapter FASTA files
        ex_generate_demux_adaptors.py \
            --adapter_fasta_outputs {output.adapter_fasta_outputs} \
            --config '{params.config_json}' \
            --log {log} 2>> {log}
        """