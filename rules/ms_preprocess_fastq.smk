"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: 
    - Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files

Author: Joshua Johnstone

"""

# Trims and filters reads
    # Trims adaptors
    # Trims poly-G artifacts (>10 Gs at 3' end)
    # Trims bases of quality <20 from read ends
    # Removes reads less than 100bp after trimming
rule ms_trim_filter_fastqs:
    input:
        r1 = lambda wc: ms_samples.query(f"ms_sample == '{wc.ms_sample}'")["fastq1"].values[0],
        r2 = lambda wc: ms_samples.query(f"ms_sample == '{wc.ms_sample}'")["fastq2"].values[0]
    output:
        r1 = temp("tmp/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample}/{ms_sample}_trimfilter_r2.fastq.gz"),
        report = "metrics/{ms_sample}/{ms_sample}_trimfilter_metrics.tsv"
    threads: 
        max(1, os.cpu_count() // 4)
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
            --report=minimal > {output.report}
        """
