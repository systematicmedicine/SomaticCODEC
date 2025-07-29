"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: 
    - Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files

Authors:
    - Joshua Johnstone
    - Cameron Fraser
"""

import scripts.get_metadata as md

"""
Moves the read pair UMI to readname
    - Cut 3bp from the start of the read 1 and read 2 sequence
    - Append read 1 3bp UMI sequence to the readname of read 1 and read 2
    - Append read 2 3bp UMI sequence after read 1 UMI in read 1 and read 2
""" 
rule ms_extract_fastq_umis:
    input:
        ms_samples = config["ms_samples_path"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_umi_extracted_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_umi_extracted_r2.fastq.gz")
    log:
        "logs/{ms_sample}/ms_extract_umis.log"
    benchmark:
        "logs/{ms_sample}/ms_extract_umis.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
          -j {threads} \
          --cut 3 \
          -U 3 \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o {output.r1} \
          -p {output.r2} \
          {input.r1} {input.r2} 2>> {log}
        """


"""
Trims FASTQ files
    - Adaptors
    - Poly-G artifacts (>10 Gs at 3' end)
    - Trims bases of quality <20 from read ends
"""
rule ms_trim_fastq:
    input:
        ms_samples = config["ms_samples_path"],
        r1 = "tmp/{ms_sample}/{ms_sample}_umi_extracted_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_umi_extracted_r2.fastq.gz"
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_trim_metrics.tsv"
    params:
        adaptor_1 = config["ms_trim_fastq"]["adaptor_1"],
        adaptor_2 = config["ms_trim_fastq"]["adaptor_2"]
    log:
        "logs/{ms_sample}/ms_trim_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_trim_fastq.benchmark.txt"
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
            -j {threads} \
            -a {params.adaptor_1} \
            -A {params.adaptor_2} \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff 20 \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=minimal > {output.report} 2>> {log}
        """


"""
Filters FASTQ files
    - Reads < 100 base pairs
"""
rule ms_filter_fastq:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_trim_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_trim_r2.fastq.gz",    
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_filter_metrics.tsv"
    log:
        "logs/{ms_sample}/ms_filter_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_filter_fastq.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
            -j {threads} \
            --minimum-length 100 \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=minimal > {output.report} 2>> {log}
        """