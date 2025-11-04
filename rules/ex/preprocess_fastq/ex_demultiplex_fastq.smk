"""
Demultiplex each lane FASTQ into sample FASTQs
    - Use the 18bp sample indices to match reads to samples
"""

import helpers.get_metadata as md

rule ex_demultiplex_fastq:
    input:
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        ex_samples = config["metadata"]["ex_samples_metadata"],
        raw_r1 = expand("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz", ex_lane = md.get_ex_lane_ids(config)),
        raw_r2 = expand("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz", ex_lane = md.get_ex_lane_ids(config)),
        r1_start = expand("tmp/{ex_lane}/{ex_lane}_r1_start.fasta", ex_lane = md.get_ex_lane_ids(config)),
        r2_start = expand("tmp/{ex_lane}/{ex_lane}_r2_start.fasta", ex_lane = md.get_ex_lane_ids(config))
    output:
        demuxed_r1 = 
            temp(expand("tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz", 
            ex_sample = md.get_ex_sample_ids(config))) + 
            temp(expand("tmp/{ex_technical_control}/{ex_technical_control}_r1_demux.fastq.gz", 
            ex_technical_control = md.get_ex_technical_control_ids(config))),
        demuxed_r2 = 
            temp(expand("tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz", 
            ex_sample = md.get_ex_sample_ids(config))) + 
            temp(expand("tmp/{ex_technical_control}/{ex_technical_control}_r2_demux.fastq.gz", 
            ex_technical_control = md.get_ex_technical_control_ids(config))),
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
    script:
        os.path.join(workflow.basedir, "scripts", "ex_demultiplex_fastq.py")