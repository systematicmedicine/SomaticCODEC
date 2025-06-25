"""
--- ms_preprocess_fastq.smk ---

Rules for performing fastqc, adaptor trimming, and quality filtering on demuxed ms FASTQs.

Input: Demuxed FASTQ files generated from Illumina sequencing of Illumina PCR-free libraries 
Outputs: 
    - Processed ms FASTQ files
    - Metrics files

Author: Joshua Johnstone

"""

# Create dict of matched sample raw FASTQ files
ms_raw_fastq_dict = (
    ms_samples.set_index("ms_sample_name")[["fastq1", "fastq2"]]
    .to_dict(orient="index")
)

# Generates a fastqc report for the demuxed FASTQs
rule ms_fastqc_raw:
    input:
        r1 = lambda wc: pd.read_csv(config["ms_samples_path"]).query(f"ms_sample_name == '{wc.ms_sample_name}'")["fastq1"].values[0],
        r2 = lambda wc: pd.read_csv(config["ms_samples_path"]).query(f"ms_sample_name == '{wc.ms_sample_name}'")["fastq2"].values[0]
    output:
        r1_report = "metrics/{ms_sample_name}/{ms_sample_name}_r1_raw_fastqc.html",
        r2_report = "metrics/{ms_sample_name}/{ms_sample_name}_r2_raw_fastqc.html"
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)
        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample_name} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample_name}/${{r1_base}}_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample_name}/${{r2_base}}_fastqc.html {output.r2_report}
        """

# Trims and filters reads
    # Trims adaptors
    # Trims poly-G artifacts (>10 Gs at 3' end)
    # Trims bases of quality <20 from read ends
    # Removes reads less than 100bp after trimming
rule ms_trim_filter:
    input:
        r1 = lambda wc: pd.read_csv(config["ms_samples_path"]).query(f"ms_sample_name == '{wc.ms_sample_name}'")["fastq1"].values[0],
        r2 = lambda wc: pd.read_csv(config["ms_samples_path"]).query(f"ms_sample_name == '{wc.ms_sample_name}'")["fastq2"].values[0]
    output:
        r1 = temp("tmp/{ms_sample_name}/{ms_sample_name}_trimfilter_r1.fastq.gz"),
        r2 = temp("tmp/{ms_sample_name}/{ms_sample_name}_trimfilter_r2.fastq.gz"),
        report = "metrics/{ms_sample_name}/{ms_sample_name}_trimfilter_metrics.tsv"
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

# Generates a fastqc report for processed reads
rule ms_fastqc_processed:
    input:
        r1 = "tmp/{ms_sample_name}/{ms_sample_name}_trimfilter_r1.fastq.gz",
        r2 = "tmp/{ms_sample_name}/{ms_sample_name}_trimfilter_r2.fastq.gz"
    output:
        r1_report = "metrics/{ms_sample_name}/{ms_sample_name}_trimfilter_r1_fastqc.html",
        r2_report = "metrics/{ms_sample_name}/{ms_sample_name}_trimfilter_r2_fastqc.html"
    threads:
        max(1, os.cpu_count() // 16)
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)
        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample_name} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample_name}/${{r1_base}}_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample_name}/${{r2_base}}_fastqc.html {output.r2_report}
        """