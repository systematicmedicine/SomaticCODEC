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
rule fastqc_demuxed_FASTQ:
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

# Auto-detects and trims adaptors 
# Trims bases with quality <15 from read ends 
# Filters reads that are shorter than 15 bases after trimming
# Filters reads that have >40% bases with quality <15
# Filters reads that have more than 5 Ns
rule trim_filter:
    input:
        r1 = "tmp/data/{sample}_r1.fastq.gz",
        r2 = "tmp/data/{sample}_r2.fastq.gz"
    output:
        r1_processed = "tmp/data/{sample}_processed_r1.fastq.gz",
        r2_processed = "tmp/data/{sample}_processed_r2.fastq.gz",
        html = "tmp/metrics/fastp/{sample}_fastp.html",
        json = "tmp/metrics/fastp/{sample}_fastp.json"
    threads: 8
    shell: 
        """
        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.r1_processed} \
            -O {output.r2_processed} \
            --detect_adapter_for_pe \
            --thread {threads} \
            --qualified_quality_phred 15 \
            --length_required 15 \
            --unqualified_percent_limit 40 \
            --n_base_limit 5 \
            --html {output.html} \
            --json {output.json}
        """

# Generates a new fastqc report for processed reads
rule fastqc_processed:
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