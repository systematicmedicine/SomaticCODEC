"""
--- ex_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.
Specific to the ex section of the pipeline.

Authors: 
    - James Phie

"""

# ex_lane_to_sample has been moved to ex_preprocess_fastq (and was renamed from samples_by_lane)

# FastQC on raw fastq files (before demultiplexing or any processing)
rule ex_fastqcraw_metrics:
    input:
        fastq1 = lambda wildcards: ex_raw_r1_list[wildcards.ex_lane],
        fastq2 = lambda wildcards: ex_raw_r2_list[wildcards.ex_lane]
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
        trim_reports = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_filter_metrics.json", ex_sample=samples_by_lane[wildcards.ex_lane]),
        flagstats = lambda wildcards: expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=samples_by_lane[wildcards.ex_lane])
    output:
        "metrics/{ex_lane}/{ex_lane}_correctproduct_metrics.txt"
    params:
        samples = lambda wildcards: samples_by_lane[wildcards.ex_lane]
    script:
        "../scripts/correctproduct.py"

# Custom python script to assess how many unused indices were detected from other experiments (similar metrics to rawreadcounts). This should always be 0. 
rule ex_batchcontamination_metrics:
    input:
        json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json"
    output:
        contamination = "metrics/{ex_lane}/{ex_lane}_batchcontamination_metrics.txt"
    params:
        fasta = lambda wildcards: f"tmp/adapter_fastas/{wildcards.ex_lane}_r1start.fasta",
        used = config['ex_samples_path']
    script:
        "../scripts/batchcontamination.py"

# Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf",
    resources:
        mem = 32
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
        expand("metrics/{ex_sample}/{ex_sample}_map_umi3_metrics.txt", ex_sample=ex_sample_names)
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
        fasta = lambda wildcards: f"tmp/adapter_fastas/{wildcards.ex_lane}_r1start.fasta",
        used = config['ex_samples_path']
    script:
        "../scripts/rawreadcounts.py"

# Depth and genome territory covered, applied to the dsc bam
rule ex_dscdepth_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_mapQ.bam", #Update to "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam" once fgbio is complete
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_depth_metrics.txt",
    resources:
        mem = 30
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectWgsMetrics \
            I={input.bam} \
            O={output.metrics} \
            R={input.ref} \
            INCLUDE_BQ_HISTOGRAM=true \
            MINIMUM_BASE_QUALITY=30
        """

# Generates a pass/fail report for all component level metrics
rule component_metrics_report:
    input:
        expand("metrics/{ms_sample}/{ms_sample}_mask_metrics.txt", ms_sample = ms_sample_names),
        expand("metrics/{ex_sample}/{ex_sample}_map_metrics.txt", ex_sample=ex_sample_names)
    output:
        report = "metrics/component_metrics_report.csv"
    script:
        "scripts/component_metrics_report.R"