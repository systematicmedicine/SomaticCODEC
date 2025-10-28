"""
Trims FASTQ files
    - Spacer from 5' end of reads
    - Adaptors
    - Poly-G artifacts (>10 Gs at 3' end)
    - Bases of quality < qual_trim_threshold from read ends
"""

import helpers.get_metadata as md

rule ms_trim_fastq:
    input:
        setup_files = setup_files,
        ms_samples = config["metadata"]["ms_samples_metadata"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        intermediate_spacer_removed_r1 = temp("tmp/{ms_sample}/{ms_sample}_spacer_removed_r1.fastq.gz"),
        intermediate_spacer_removed_r2 = temp("tmp/{ms_sample}/{ms_sample}_spacer_removed_r2.fastq.gz"),
        r1 = temp("tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_trim_metrics.txt"
    params:
        adaptor_1 = config["sci_params"]["ms_trim_fastq"]["adaptor_1"],
        adaptor_2 = config["sci_params"]["ms_trim_fastq"]["adaptor_2"],
        spacer_length = config["sci_params"]["ms_trim_fastq"]["spacer_length"],
        qual_trim_threshold = config["sci_params"]["ms_trim_fastq"]["qual_trim_threshold"],
        max_error_rate = config["sci_params"]["ms_trim_fastq"]["max_error_rate"],
        min_overlap = config["sci_params"]["ms_trim_fastq"]["min_overlap"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_trim_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_trim_fastq.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        cutadapt \
          -j {threads} \
          -u {params.spacer_length} \
          -U {params.spacer_length} \
          -o {output.intermediate_spacer_removed_r1} \
          -p {output.intermediate_spacer_removed_r2} \
          --compression-level {params.compression_level} \
          {input.r1} {input.r2} 2>> {log}
        
        cutadapt \
            -j {threads} \
            -a {params.adaptor_1} \
            -A {params.adaptor_1} \
            -a {params.adaptor_2} \
            -A {params.adaptor_2} \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff {params.qual_trim_threshold} \
            -e {params.max_error_rate} \
            -O {params.min_overlap} \
            -o {output.r1} \
            -p {output.r2} \
            --compression-level {params.compression_level} \
            {output.intermediate_spacer_removed_r1} {output.intermediate_spacer_removed_r2} \
            --report=full > {output.report} 2>> {log}
        """