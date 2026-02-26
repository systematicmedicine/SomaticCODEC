"""
Filters FASTQ files
    - Reads less than minimum length
    - Reads with low average quality
"""

from definitions.paths.io import ms as MS

rule ms_filter_fastq:
    input:
        r1 = MS.TRIMMED_FASTQ_R1,
        r2 = MS.TRIMMED_FASTQ_R2,    
    output:
        r1 = temp(MS.FILTERED_FASTQ_R1),
        r2 = temp(MS.FILTERED_FASTQ_R2),
        filter_metrics = MS.MET_FILTER_FASTQ
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
        # Filter for length and average quality
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