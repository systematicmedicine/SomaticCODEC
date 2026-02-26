"""
FastQC on raw fastq files (before demultiplexing or any processing)
"""

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "outputs", "pipeline_outputs.smk")

import helpers.get_metadata as md
from definitions.paths.io import ex as EX

rule ex_fastqcraw_metrics:
    input:
        shared_setup = shared_setup,
        ex_lanes = config["metadata"]["ex_lanes_metadata"],
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1],
    output:
        fastqc_report1 = EX.MET_FASTQC_RAW_HTML_R1,
        fastqc_report2 = EX.MET_FASTQC_RAW_HTML_R2,
        zip_r1 = temp(EX.MET_FASTQC_RAW_INT_R1),
        zip_r2 = temp(EX.MET_FASTQC_RAW_INT_R2),
        txt_r1 = EX.MET_FASTQC_RAW_TXT_R1,
        txt_r2 = EX.MET_FASTQC_RAW_TXT_R2
    log:
        "logs/{ex_lane}/ex_fastqcraw_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqcraw_metrics.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["light"]
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        MEMORY_PER_FILE=$(( {resources.memory} * 1024 / 2 ))

        # Run fastqc
        fastqc \
        --memory $MEMORY_PER_FILE \
        -t {threads} \
         -o metrics/ \
        {input.fastq1} {input.fastq2} 2>> {log}

        # Rename outputs
        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}
        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}

        # Extract txt file from zip output
        unzip -p {output.zip_r1} */fastqc_data.txt > {output.txt_r1} 2>> {log}
        unzip -p {output.zip_r2} */fastqc_data.txt > {output.txt_r2} 2>> {log}
        """