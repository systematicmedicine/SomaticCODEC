"""
Generates adapter FASTA files for demultiplexing
"""

import helpers.get_metadata as md
from definitions.paths.io.ex import core as C
import json

rule ex_generate_demux_adaptors:
    input:
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"],
        ex_technical_controls = config["metadata"]["ex_technical_controls_metadata"],
        ex_adapters = config["metadata"]["ex_adapters_metadata"]
    output:
        r1_start = C.ADAPTOR_R1_START,
        r2_start = C.ADAPTOR_R2_START
    params:
        adapter_dict = json.dumps(md.get_ex_lane_adapter_dict(config))
    log:
        "logs/global_rules/ex_generate_demux_adaptors/{ex_lane}.log"
    benchmark:
        "logs/global_rules/ex_generate_demux_adaptors/{ex_lane}.benchmark.txt"
    threads:
        1
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
          --r1_start '{output.r1_start}' \
          --r2_start '{output.r2_start}' \
          --log {log} 2>> {log}
        """