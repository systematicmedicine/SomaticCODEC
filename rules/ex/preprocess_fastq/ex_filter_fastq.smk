"""
Filter reads
    - Remove reads that are too short
    - Remove reads where the mean quality score is too low
"""

import helpers.get_metadata as md
from definitions.paths.io.ex import core as C

rule ex_filter_fastq:
    input: 
        r1 = C.TRIMMED_FASTQ_R1,
        r2 = C.TRIMMED_FASTQ_R2,  
    output:
        r1 = temp(C.FILTERED_FASTQ_R1),
        r2 = temp(C.FILTERED_FASTQ_R2),
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
        # Filter reads
        trimmomatic -Xmx{resources.memory}g -Djava.io.tmpdir=tmp PE \
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