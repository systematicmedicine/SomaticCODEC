"""
Generates a fastqc report for ms processed reads
"""

from definitions.paths.io import ms as MS

rule ms_processed_fastq_metrics:
    input:
        r1 = MS.FILTERED_FASTQ_R1,
        r2 = MS.FILTERED_FASTQ_R2
    output:
        r1_report = MS.MET_FASTQC_FILTER_HTML_R1,
        r2_report = MS.MET_FASTQC_FILTER_HTML_R2,
        r1_zip = temp(MS.MET_FASTQC_FILTER_INT_R1),
        r2_zip = temp(MS.MET_FASTQC_FILTER_INT_R2),
        r1_txt = MS.MET_FASTQC_FILTER_TXT_R1,
        r2_txt = MS.MET_FASTQC_FILTER_TXT_R2
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
        {input.r1} {input.r2} &>> {log}

        # Extract txt file from zip output
        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}
        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """
