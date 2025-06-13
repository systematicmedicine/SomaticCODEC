"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Author: James Phie

"""
# Replace default index names with experiment specific sample names as defined in ex_samples.csv
rule ex_namesamples:
    input:
        r1start=config['r1start'],
        r1end=config['r1end'],
        r2start=config['r2start'],
        r2end=config['r2end'],
        mapping=config['ex_samples'],
    output:
        r1start_out="tmp/r1start.fasta",
        r1end_out="tmp/r1end.fasta",
        r2start_out="tmp/r2start.fasta",
        r2end_out="tmp/r2end.fasta"
    script:
        "../scripts/samplenames.py"

# FastQC on raw fastq files (before demultiplexing or any processing)
rule ex_fastqcraw_metrics:
    input:
        fastq1 = ex_raw_fastq1,
        fastq2 = ex_raw_fastq2
    output:
        fastqc_report1 = "metrics/r1_fastqc_raw_metrics.html",
        fastqc_report2 = "metrics/r2_fastqc_raw_metrics.html"
    resources:
        mem = 8,
        runtime = 24
    shell:
        """
        fastqc {input.fastq1} -o metrics/
        fastqc {input.fastq2} -o metrics/

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        """

# Removes first 3bp of R1 and R2 to read name as 6 base UMI. Demultiplexes using R1 and R2 5' sample indices (both must agree). Trims 5' sample indices. 
rule ex_demux:
    input:
        fastq1 = ex_raw_fastq1,
        fastq2 = ex_raw_fastq2,
        r1_start = "tmp/r1start.fasta",
        r2_start = "tmp/r2start.fasta"
    output:
        demuxed_r1 = temp(expand("tmp/{ex_sample}_r1_raw.fastq.gz", ex_sample=ex_sample_names)),
        demuxed_r2 = temp(expand("tmp/{ex_sample}_r2_raw.fastq.gz", ex_sample=ex_sample_names)),
        json = "metrics/demux_metrics.json"
    threads:
        config['ncores']
    shell:
        """
        #Trim the UMI (first 3 bases) of each read and append to read name
        #Demultiplex PE reads based on sample indice on read 1
        #Trim 5' sample indices from read 1 and read 2
        cutadapt \
          -j {threads} \
          --no-indels \
          -e 2 \
          -g ^file:{input.r1_start} \
          -G ^file:{input.r2_start} \
          --cut 3 \
          -U 3 \
          --pair-adapters \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o tmp/{{name}}_r1_raw.fastq.gz \
          -p tmp/{{name}}_r2_raw.fastq.gz \
          {input.fastq1} {input.fastq2} \
          --report=full > {output.report} \
          --json={output.json}
        """

# Identifies and trims 3' sample indices from R1 and R2 when present
rule ex_trim:
    input:
        r1 = "tmp/{ex_sample}_r1_raw.fastq.gz",
        r2 = "tmp/{ex_sample}_r2_raw.fastq.gz",
        r1_end = "tmp/r1end.fasta",
        r2_end = "tmp/r2end.fasta"
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_trim_metrics.json"
    threads:
        config['ncores']
    shell:
        """
        #Trim 1bp from 5' end (T from ligation)
        #Trim 3' indices/adapters
        cutadapt \
          -j {threads} \
          --cut 1 \
          -U 1 \
          -e 1 \
          -O 7 \
          -a file:{input.r1_end} \
          -A file:{input.r2_end} \
          -o {output.r1} \
          -p {output.r2} \
          {input.r1} {input.r2} \
          --report=full > {output.report} \
          --json={output.json}
        """

# Trims 5' and 3' ends to remove residual adapter/A-tailing bases. Filters inserts size <15bp. 
rule ex_trimfilter:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trimfilter.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trimfilter.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_trimfilter_metrics.json"
    threads:
        config['ncores']
    shell:  
        """
        #Trim 8 bases from 3' end of read 1 and read 2 to remove any remaining short (<7bp) sample indices.
        #8 base trimming could be relaxed as duplex seq will detect and filter adapters due to R1R2 disagree later. 
        #The trim also removes poly A-tails from ligation. 
        #Filter for insert length <15bp
        cutadapt \
        -j {threads} \
        -u -8 \
        -U -8 \
        -u 2 \
        -U 2 \
        --minimum-length 70 \
        --quality-cutoff 20 \
        -o {output.r1} \
        -p {output.r2} \
        {input.r1} {input.r2} \
        --report=full > {output.report} \
        --json={output.json}
        """

# FastQC on demultiplexed, trimmed FASTQs 
rule ex_fastqctrim_metrics:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_trimfilter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_trimfilter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_trimfilter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_trimfilter_metrics.html"
    shell:
        """
        fastqc {input.fastq1} -o metrics/{wildcards.ex_sample}
        fastqc {input.fastq2} -o metrics/{wildcards.ex_sample}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        """

# Custom python script to assess demultiplexing. 
rule ex_rawreadcounts_metrics:
    input:
        json = "metrics/demux_metrics.json"
    output:
        readcounts = "metrics/sample_readcounts_metrics.txt"
    params:
        fasta = config['r1start'],
        used = ex_sample_names
    script:
        "../scripts/rawreadcounts.py"

# Custom python script to assess how many unused indices were detected from other experiments (similar metrics to rawreadcounts). This should always be 0. 
rule ex_batchcontamination_metrics:
    input:
        json = "metrics/demux_metrics.json"
    output:
        contamination = "metrics/batchcontamination_metrics.txt"
    params:
        fasta = config['r1start'],
        used = ex_sample_names
    script:
        "../scripts/batchcontamination.py"