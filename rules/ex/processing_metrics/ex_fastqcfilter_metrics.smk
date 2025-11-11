"""
FastQC on demultiplexed, trimmed, filtered FASTQs 
"""
rule ex_fastqcfilter_metrics:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.html",
        zip_r1 = temp("metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.zip"),
        zip_r2 = temp("metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.zip"),
        txt_r1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt",
        txt_r2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt"
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
        {input.fastq1} {input.fastq2} 2>> {log}

        # Rename outputs
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}

        # Extract txt file from zip output
        unzip -p {output.zip_r1} */fastqc_data.txt > {output.txt_r1} 2>> {log}
        unzip -p {output.zip_r2} */fastqc_data.txt > {output.txt_r2} 2>> {log}
        """