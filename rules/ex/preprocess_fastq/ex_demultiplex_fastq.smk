"""
Demultiplex each lane FASTQ into sample FASTQs
    - Use the 18bp sample indices to match reads to samples
"""

import helpers.get_metadata as md
from definitions.paths.io.ex import core as C

rule ex_demultiplex_fastq:
    input:
        # UMI extracted FASTQs
        umixd_r1 = expand(C.UMIXD_FASTQ_R1, ex_lane = md.get_ex_lane_ids(config)),
        umixd_r2 = expand(C.UMIXD_FASTQ_R2, ex_lane = md.get_ex_lane_ids(config)),

        # Demultiplex adaptors
        r1_start = expand(C.ADAPTOR_R1_START, ex_lane = md.get_ex_lane_ids(config)),
        r2_start = expand(C.ADAPTOR_R2_START, ex_lane = md.get_ex_lane_ids(config)),

        # Sample metadata
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"]

    output:
        # Demultiplexed FASTQs
        demuxed_r1 = 
            temp(expand(C.DEMUXD_FASTQ_R1, ex_sample = md.get_ex_sample_ids(config))) + 
            temp(expand("tmp/{ex_technical_control}/{ex_technical_control}_r1_demux.fastq.gz", ex_technical_control = md.get_ex_technical_control_ids(config))),
        demuxed_r2 = 
            temp(expand(C.DEMUXD_FASTQ_R2, ex_sample = md.get_ex_sample_ids(config))) + 
            temp(expand("tmp/{ex_technical_control}/{ex_technical_control}_r2_demux.fastq.gz", ex_technical_control = md.get_ex_technical_control_ids(config))),
        
        # Metrics files
        metrics = expand("metrics/{ex_lane}/{ex_lane}_demux_metrics.txt", ex_lane = md.get_ex_lane_ids(config))
        
    params:
        max_error_rate = config["sci_params"]["ex_demultiplex_fastq"]["max_error_rate"],
        min_adapter_overlap = config["sci_params"]["ex_demultiplex_fastq"]["min_adapter_overlap"],
        lane_ids = md.get_ex_lane_ids(config),
        suffix_r1 = "r1_demux.fastq.gz",
        suffix_r2 = "r2_demux.fastq.gz",
        out_dir = "tmp",
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/global_rules/ex_demultiplex_fastq.log"
    benchmark:
        "logs/global_rules/ex_demultiplex_fastq.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Demulitplex
        ex_demultiplex_fastq.py \
            --raw_r1 {input.umixd_r1} \
            --raw_r2 {input.umixd_r2} \
            --r1_start {input.r1_start} \
            --r2_start {input.r2_start} \
            --metrics {output.metrics} \
            --max_error_rate {params.max_error_rate} \
            --min_adapter_overlap {params.min_adapter_overlap} \
            --lane_ids {params.lane_ids} \
            --suffix_r1 {params.suffix_r1} \
            --suffix_r2 {params.suffix_r2} \
            --out_dir {params.out_dir} \
            --compression_level {params.compression_level} \
            --threads {threads} \
            --log {log} 2>> {log}
        """