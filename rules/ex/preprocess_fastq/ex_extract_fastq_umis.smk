"""
Moves the read pair UMI to readname
    - Cut 3bp from the start of the read 1 and read 2 sequence
    - Append read 1 3bp UMI sequence to the readname of read 1 and read 2
    - Append read 2 3bp UMI sequence after read 1 UMI in read 1 and read 2
""" 

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "outputs", "pipeline_outputs.smk")

import helpers.get_metadata as md

# Rule
rule ex_extract_fastq_umis:
    input:
        global_setup = global_setup,
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1]
    output:
        fastq1 = temp("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"),
        fastq2 = temp("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz")
    params:
        umi_length = config["sci_params"]["ex_extract_fastq_umis"]["umi_length"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_lane}/ex_extract_fastq_umis.log"
    benchmark:
        "logs/{ex_lane}/ex_extract_fastq_umis.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Move UMIs from sequence to read name
        cutadapt \
          -j {threads} \
          --cut {params.umi_length} \
          -U {params.umi_length} \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o {output.fastq1} \
          -p {output.fastq2} \
          --compression-level {params.compression_level} \
          {input.fastq1} {input.fastq2} 2>> {log}
        """