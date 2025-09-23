"""
--- ex_demultiplex.smk ---

Rules for demultiplexing lane FASTQ files into experimental sample and control FASTQs

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Outputs: Demuxed experimental sample and control FASTQ files

Authors: 
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
"""
import helpers.get_metadata as md


"""
Moves the read pair UMI to readname
    - Cut 3bp from the start of the read 1 and read 2 sequence
    - Append read 1 3bp UMI sequence to the readname of read 1 and read 2
    - Append read 2 3bp UMI sequence after read 1 UMI in read 1 and read 2
""" 
rule ex_extract_fastq_umis:
    input:
        setup_files = setup_files,
        ex_lanes = config["files"]["ex_lanes_metadata"],
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1]
    output:
        fastq1 = temp("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"),
        fastq2 = temp("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz")
    params:
        umi_length = config["rules"]["ex_extract_fastq_umis"]["umi_length"]
    log:
        "logs/{ex_lane}/ex_extract_umis.log"
    benchmark:
        "logs/{ex_lane}/ex_extract_umis.benchmark.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        cutadapt \
          -j {threads} \
          --cut {params.umi_length} \
          -U {params.umi_length} \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o {output.fastq1} \
          -p {output.fastq2} \
          {input.fastq1} {input.fastq2} 2>> {log}
        """


"""
Generates adapter FASTA files for demultiplexing
"""
rule ex_generate_demux_adaptors:
    input:
        ex_lanes = config["files"]["ex_lanes_metadata"],
        ex_samples = config["files"]["ex_samples_metadata"],
        ex_adapters = config["files"]["ex_adapters_metadata"]
    output:
        adapter_fasta_outputs = expand(
            "tmp/{ex_lane}/{ex_lane}_{region}.fasta",
            ex_lane = md.get_ex_lane_ids(config),
            region = ["r1_start", "r1_end", "r2_start", "r2_end"]
        )
    log:
        "logs/pipeline/ex_generate_demux_adaptors.log"
    benchmark:
        "logs/pipeline/ex_generate_demux_adaptors.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_generate_demux_adaptors.py"


"""
Demultiplex each lane FASTQ into sample FASTQs
    - Use the 18bp sample indices to match reads to samples
""" 
rule ex_demultiplex_fastq:
    input:
        ex_lanes = config["files"]["ex_lanes_metadata"],
        ex_samples = config["files"]["ex_samples_metadata"],
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
        max_error_rate = config["rules"]["ex_demultiplex_fastq"]["max_error_rate"],
        min_adapter_overlap = config["rules"]["ex_demultiplex_fastq"]["min_adapter_overlap"],
        lane_ids = md.get_ex_lane_ids(config),
        suffix_r1 = "r1_demux.fastq.gz",
        suffix_r2 = "r2_demux.fastq.gz",
        out_dir = "tmp"
    log:
        "logs/batch/ex_demultiplex_fastq.log"
    benchmark:
        "logs/batch/ex_demultiplex_fastq.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    script:
        "../scripts/ex_demultiplex.py"

