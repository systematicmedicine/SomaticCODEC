# ====================================================================================
# 
#   ms_raw_fastq_metrics.smk
#
#   Generates a fastqc report for demuxed ms FASTQs
#
#   Authors: 
#        - Joshua Johnstone
#        - Cameron Fraser
#
# ====================================================================================

# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "pipeline_outputs.smk")

import helpers.get_metadata as md

rule ms_raw_fastq_metrics:
    input:
        global_setup = global_setup,
        ms_samples = config["metadata"]["ms_samples_metadata"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html",
        r1_zip = temp("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.zip"),
        r2_zip = temp("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.zip"),
        r1_txt = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt",
        r2_txt = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt"
    log:
        "logs/{ms_sample}/ms_raw_fastq_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_raw_fastq_metrics.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["light"]
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)

        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.html {output.r1_report} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.html {output.r2_report} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.zip {output.r1_zip} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.zip {output.r2_zip} 2>> {log}

        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}

        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """