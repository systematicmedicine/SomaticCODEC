"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files
    - Metrics files

Author: Joshua Johnstone

"""

# Combines reads from samples run across two lanes
rule combine_lanes:
    input:
        r1_l5 = "tmp/data/{sample}_L005_R1.fastq.gz",
        r2_l5 = "tmp/data/{sample}_L005_R2.fastq.gz",
        r1_l6 = "tmp/data/{sample}_L006_R1.fastq.gz",
        r2_l6 = "tmp/data/{sample}_L006_R1.fastq.gz"
    output:
        r1 = "tmp/data/{sample}_r1.fastq.gz",
        r2 = "tmp/data/{sample}_r2.fastq.gz"
    shell:
        """
        cat {input.r1_l5} {input.r1_l6} > {output.r1} \
        cat {input.r2_l5} {input.r2_l6} > {output.r1}

        """


# Generates a fastqc report for the demuxed FASTQs
rule ms_fastqc_raw:
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
# -a CTGTCTCTTATACACATCT is the transposase ME sequence
# -A ATGTGTATAAGAGACA is the ME sequence reverse complement
# Trims poly-G artifacts (>10 Gs at 3' end)
# Trims bases of quality <20
# Removes reads less than 100bp after trimming

rule ms_trim_filter:
    input:
        r1 = "tmp/data/{sample}_r1.fastq.gz",
        r2 = "tmp/data/{sample}_r2.fastq.gz"
    output:
        r1 = "tmp/data/{sample}_processed_r1.fastq.gz",
        r2 = "tmp/data/{sample}_processed_r2.fastq.gz",
        report = "tmp/metrics/cutadapt/{sample}_trimfilter_metrics.html",
        json = "tmp/metrics/cutadapt/{sample}_trimfilter_metrics.json"
    threads: 8
    shell: 
        """
        cutadapt \
            -j {threads} \
            -a CTGTCTCTTATACACATCT \
            -A CTGTCTCTTATACACATCT \
            -a ATGTGTATAAGAGACA \
            -A ATGTGTATAAGAGACA \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff 20 \
            --minimum-length 100 \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=full > {output.report} \
            --json={output.json}

        """
# Generates a new fastqc report for processed reads
rule ms_fastqc_processed:
    input:
        r1 = "tmp/data/{sample}_processed_r1.fastq.gz",
        r2 = "tmp/data/{sample}_processed_r2.fastq.gz"
    output:
        r1_report = "tmp/metrics/fastqc/processed/{sample}_processed_r1_fastqc.html",
        r2_report = "tmp/metrics/fastqc/processed/{sample}_processed_r2_fastqc.html"
    threads: 4
    shell:
        """
        fastqc -t {threads} -o tmp/metrics/fastqc/processed {input.r1} {input.r2}

        """