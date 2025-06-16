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
rule ms_fastqc_raw:
    input:
        r1 = "tmp/{ms_sample}/{ms_fastq1}",
        r2 = "tmp/{ms_sample}/{ms_fastq2}"
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html"
    threads: 4
    shell:
        """
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample}/$(basename {wildcards.ms_fastq1} .fastq.gz)_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample}/$(basename {wildcards.ms_fastq2} .fastq.gz)_fastqc.html {output.r2_report}

        """

# Identifies and trims adaptors
# -a CTGTCTCTTATACACATCT is the transposase ME sequence
# -A ATGTGTATAAGAGACA is the ME sequence reverse complement
# Trims poly-G artifacts (>10 Gs at 3' end)
# Trims bases of quality <20
# Removes reads less than 100bp after trimming

rule ms_trim_filter:
    input:
        r1 = "tmp/{ms_sample}/{ms_fastq1}",
        r2 = "tmp/{ms_sample}/{ms_fastq2}"
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_trimfilter_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_trimfilter_metrics.html"
    threads: 8
    shell: 
        """
        cutadapt \
            -j {threads} \
            -a {config[ms_adaptor_1]} \
            -A {config[ms_adaptor_1]} \
            -a {config[ms_adaptor_2]} \
            -A {config[ms_adaptor_2]} \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff 20 \
            --minimum-length 100 \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            --report=full > {output.report}

        """
# Generates a new fastqc report for processed reads
rule ms_fastqc_processed:
    input:
        r1 = "metrics/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz",
        r2 = "metrics/{ms_sample}/{ms_sample}_trimfilter_r2.fastq.gz"
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_trimfilter_r1_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_trimfilter_r2_fastqc.html"
    threads: 4
    shell:
        """
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample}/$(basename {input.r1} .fastq.gz)_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample}/$(basename {input.r2} .fastq.gz)_fastqc.html {output.r2_report}

        """