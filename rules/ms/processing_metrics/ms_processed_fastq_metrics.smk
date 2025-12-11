"""
Generates a fastqc report for ms processed reads
"""

rule ms_processed_fastq_metrics:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.html",
        r1_zip = temp("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.zip"),
        r2_zip = temp("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.zip"),
        r1_txt = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt",
        r2_txt = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt"
    log:
        "logs/{ms_sample}/ms_processed_fastq_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_processed_fastq_metrics.benchmark.txt"
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
        -o metrics/{wildcards.ms_sample} \
        {input.r1} {input.r2} 2>> {log}

        # Extract txt file from zip output
        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}
        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """
