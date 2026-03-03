"""
FastQC on demultiplexed, trimmed, filtered FASTQs 
"""

from definitions.paths.io import ex as EX

rule ex_fastqcfilter_metrics:
    input:
        fastq1 = EX.FILTERED_FASTQ_R1,
        fastq2 = EX.FILTERED_FASTQ_R2
    output:
        fastqc_report1 = EX.MET_FASTQC_FILTER_HTML_R1,
        fastqc_report2 = EX.MET_FASTQC_FILTER_HTML_R2,
        zip_r1 = temp(EX.MET_FASTQC_FILTER_INT_R1),
        zip_r2 = temp(EX.MET_FASTQC_FILTER_INT_R2),
        txt_r1 = EX.MET_FASTQC_FILTER_TXT_R1,
        txt_r2 = EX.MET_FASTQC_FILTER_TXT_R2
    log:
        "logs/{ex_sample}/ex_fastqctrim_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqctrim_metrics.benchmark.txt"
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
        -o metrics/{wildcards.ex_sample} \
        {input.fastq1} {input.fastq2} &>> {log}

        # Rename outputs
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}

        # Extract txt file from zip output
        unzip -p {output.zip_r1} */fastqc_data.txt > {output.txt_r1} 2>> {log}
        unzip -p {output.zip_r2} */fastqc_data.txt > {output.txt_r2} 2>> {log}
        """