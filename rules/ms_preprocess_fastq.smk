"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Output: Processed FASTQ files

Author: Joshua Johnstone

"""

sample = x
ref = y

rule index_ref:
    input:
        ref = ref
    output:
        "{input.ref}.bwt"
    shell:
        "bwa index {input.ref}"

rule fastqc_demuxed_FASTQ:
    input:
        r1="samples/{sample}_R1.fastq.gz",
        r2="samples/{sample}_R2.fastq.gz"
    output:
        r1_report="qc_reports/{sample}_R1_fastqc.html",
        r2_report="qc_reports/{sample}_R2_fastqc.html"
    threads: 2
    shell:
        """
        fastqc -t {threads} -o qc_reports {input.r1} {input.r2}
        """

rule trim_adaptors:
        input:
        r1 = "data/{sample}_R1.fastq",
        r2 = "data/{sample}_R2.fastq"
    output:
        r1_trimmed = "trimmed/{sample}_R1.fastq",
        r2_trimmed = "trimmed/{sample}_R2.fastq",
        html = "trimmed/{sample}_fastp.html",
        json = "trimmed/{sample}_fastp.json"
    threads: 4
    shell: 
        """
        fastp \
            -i {input.r1} \
            -I {input.r2} \
            -o {output.r1_trimmed} \
            -O {output.r2_trimmed} \
            --detect_adapter_for_pe \
            --thread {threads} \
            --html {output.html} \
            --json {output.json}
        """
