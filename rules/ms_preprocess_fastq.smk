"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files
    - Metrics files

Author: Joshua Johnstone

"""

# Generates a fastqc report for the demuxed FASTQs
rule ms_fastqc_raw_metrics:
    input:
        r1 = "tmp/data/{sample}_r1.fastq.gz",
        r2 = "tmp/data/{sample}_r2.fastq.gz"
    output:
        r1_report = "tmp/metrics/fastqc/{sample}_r1_fastqc.html",
        r2_report = "tmp/metrics/fastqc/{sample}_r2_fastqc.html"
    threads: 4
    shell:
        """
        fastqc -t {threads} -o tmp/metrics/fastqc {input.r1} {input.r2}

        """

# Identifies and trims adaptors
rule ms_trim_adaptors:
    input:
        r1 = "tmp/data/{sample}_r1.fastq.gz",
        r2 = "tmp/data/{sample}_r2.fastq.gz"
    output:
        r1 = "tmp/data/{sample}_trim_r1.fastq.gz",
        r2 = "tmp/data/{sample}_trim_r2.fastq.gz",
        report = "tmp/metrics/cutadapt/{sample}_trim_metrics.html",
        json = "tmp/metrics/cutadapt/{sample}_trim_metrics.json"
    threads: 8
    shell: 
        """
        cutadapt \
            -j {threads} \
            -a CTGTCTCTTATACACATCT \
            -A CTGTCTCTTATACACATCT \
            -a ATGTGTATAAGAGACA \
            -A ATGTGTATAAGAGACA \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=full > {output.report} \
            --json={output.json}

        """

# Trims reads by quality and filters by length and quality
# rule ms_trim_qual_filter:
#     input:
#         r1 = "tmp/data/{sample}_trim_r1.fastq.gz",
#         r2 = "tmp/data/{sample}_trim_r2.fastq.gz"
#     output:
#         r1 = "tmp/data/{sample}_trimfilter_r1.fastq.gz",
#         r2 = "tmp/data/{sample}_trimfilter_r2.fastq.gz",
#         report = "tmp/metrics/cutadapt/{sample}_trimfilter_metrics.html",
#         json = "tmp/metrics/cutadapt/{sample}_trimfilter_metrics.json"
#     threads: 8
#     shell: 
#         """
#         cutadapt \
#             {params.adapters} \
#             -q 15,15 \
#             --minimum-length {params.min_length} \
#             --max-n 5 \
#             -o {output.r1} \
#             -p {output.r2} \
#             {input.r1} {input.r2} \
#             > {output.report}

#         """


# Generates a new fastqc report for processed reads
rule ms_fastqc_trimmed:
    input:
        r1 = "tmp/data/{sample}_processed_r1.fastq.gz",
        r2 = "tmp/data/{sample}_processed_r2.fastq.gz"
    output:
        r1_report = "tmp/metrics/fastqc/{sample}_r1_processed_fastqc.html",
        r2_report = "tmp/metrics/fastqc/{sample}_r2_processed_fastqc.html"
    threads: 2
    shell:
        """
        fastqc -t {threads} -o tmp/metrics {input.r1} {input.r2}

        """