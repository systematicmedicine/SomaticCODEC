"""
--- ex_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.
Specific to the ex section of the pipeline.

Authors: 
    - James Phie

"""

# FastQC on raw fastq files (before demultiplexing or any processing)
rule ex_fastqcraw_metrics:
    input:
        fastq1 = lambda wildcards: ex_lanes.loc[ex_lanes["ex_lane"] == wildcards.ex_lane, "fastq1"].values[0],
        fastq2 = lambda wildcards: ex_lanes.loc[ex_lanes["ex_lane"] == wildcards.ex_lane, "fastq2"].values[0],
    output:
        fastqc_report1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.html",
        fastqc_report2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.html",
        zip_r1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.zip",
        zip_r2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.zip"
    shell:
        """
        fastqc {input.fastq1} -o metrics/
        fastqc {input.fastq2} -o metrics/

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2}
        """

# FastQC on demultiplexed, trimmed, filtered FASTQs 
rule ex_fastqctrim_metrics:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.html",
        zip_r1 = "metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.zip",
        zip_r2 = "metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.zip"
        
    shell:
        """
        fastqc {input.fastq1} -o metrics/{wildcards.ex_sample}
        fastqc {input.fastq2} -o metrics/{wildcards.ex_sample}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2}
        """

# Collects alignment metrics from the experimental bam mapped to the reference genome
rule ex_map_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.txt}
        """

# Replace default index names with experiment specific sample names as defined in the input.tsv
rule ex_correctproduct_metrics:
    input:
        demux_json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json",
        trim_reports = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_filter_metrics.json", ex_sample=ex_lane_to_sample[wildcards.ex_lane]),
        flagstats = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=ex_lane_to_sample[wildcards.ex_lane])
    output:
        "metrics/{ex_lane}/{ex_lane}_correctproduct_metrics.txt"
    params:
        samples = lambda wildcards: ex_lane_to_sample[wildcards.ex_lane]
    script:
        "../scripts/correctproduct.py"

# Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf", 
    resources:
        mem = 128
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100
        """

# Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
rule ex_duplication_metrics:
    input:
        expand("metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt", ex_sample=ex_samples["ex_sample"].tolist())
    output:
        "metrics/ex_duplication_metrics.txt"
    script:
        "../scripts/duplication.py"

# Custom python script to assess demultiplexing. 
rule ex_rawreadcounts_metrics:
    input:
        json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json"
    output:
        readcounts = "metrics/{ex_lane}/{ex_lane}_sample_readcounts_metrics.txt"
    params:
        fasta = lambda wildcards: f"tmp/{wildcards.ex_lane}/{wildcards.ex_lane}_r1_start.fasta",
        used = ex_samples
    script:
        "../scripts/rawreadcounts.py"