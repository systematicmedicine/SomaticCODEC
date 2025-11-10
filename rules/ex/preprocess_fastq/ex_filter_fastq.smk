"""
Filter reads
    - Remove reads that are too short
    - Remove reads where the mean quality score is too low
"""

import scripts.helpers.get_metadata as md

rule ex_filter_fastq:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"),
        filter_metrics = "metrics/{ex_sample}/{ex_sample}_filter_metrics_ex.txt"
    params:
        average_quality_threshold = config["sci_params"]["ex_filter_fastq"]["average_quality_threshold"],
        min_read_length = config["sci_params"]["ex_filter_fastq"]["min_read_length"]
    log:
        "logs/{ex_sample}/ex_filter_fastq.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_fastq.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]        
    shell:  
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Filter reads
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