"""
Generates a fastqc report for demuxed MS FASTQs
"""

import helpers.get_metadata as md
from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ms_raw_fastq_metrics:
    input:
        setup_done = L.SETUP_DONE,
        ms_samples = config["metadata"]["ms_samples_metadata"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        r1_report = MS.MET_FASTQC_RAW_HTML_R1,
        r2_report = MS.MET_FASTQC_RAW_HTML_R2,
        r1_zip = temp(MS.MET_FASTQC_RAW_INT_R1),
        r2_zip = temp(MS.MET_FASTQC_RAW_INT_R2),
        r1_txt = MS.MET_FASTQC_RAW_TXT_R1,
        r2_txt = MS.MET_FASTQC_RAW_TXT_R2
    log:
        "logs/{ms_sample}/ms_raw_fastq_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_raw_fastq_metrics.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["light"]
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        r"""
        # Set memory limit
        MEMORY_PER_FILE=$(( {resources.memory} * 1024 / 2 ))

        # Get basename for input files
        r1_base=$(basename {input.r1} | sed -E 's/(\.fastq\.gz|\.fq\.gz|\.fastq|\.fq)$//')
        r2_base=$(basename {input.r2} | sed -E 's/(\.fastq\.gz|\.fq\.gz|\.fastq|\.fq)$//')

        # Get output directory
        output_dir=$(dirname {output.r1_report})
        
        # Run fastqc
        fastqc \
        --memory $MEMORY_PER_FILE \
        -t {threads} \
        -o ${{output_dir}} \
        {input.r1} {input.r2} &>> {log}

        # Rename and move output files
        mv ${{output_dir}}/${{r1_base}}_fastqc.html {output.r1_report} 2>> {log}
        mv ${{output_dir}}/${{r2_base}}_fastqc.html {output.r2_report} 2>> {log}
        mv ${{output_dir}}/${{r1_base}}_fastqc.zip {output.r1_zip} 2>> {log}
        mv ${{output_dir}}/${{r2_base}}_fastqc.zip {output.r2_zip} 2>> {log}

        # Extract txt file from zip output
        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}
        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """