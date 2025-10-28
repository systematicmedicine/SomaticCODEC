"""
Filters FASTQ files
    - Reads less than minimum length
    - Reads with low average quality
"""

rule ms_filter_fastq:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz",    
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"),
        filter_metrics = "metrics/{ms_sample}/{ms_sample}_filter_metrics_ms.txt"
    params:
        min_read_length = config["sci_params"]["ms_filter_fastq"]["min_read_length"],
        average_quality_threshold = config["sci_params"]["ms_filter_fastq"]["average_quality_threshold"]
    log:
        "logs/{ms_sample}/ms_filter_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_filter_fastq.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        trimmomatic PE \
            -phred33 \
            -threads {threads} \
            -summary {output.filter_metrics} \
            {input.r1} \
            {input.r2} \
            {output.r1} \
            /dev/null \
            {output.r2} \
            /dev/null \
            MINLEN:{params.min_read_length} \
            AVGQUAL:{params.average_quality_threshold} 2>> {log}
        """