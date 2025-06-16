"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Author: James Phie

"""
# FastQC on raw fastq files (before demultiplexing or any processing)
rule ex_fastqcraw_metrics:
    input:
        fastq1 = lambda wildcards: ex_raw_fastq1[wildcards.lane],
        fastq2 = lambda wildcards: ex_raw_fastq2[wildcards.lane]
    output:
        fastqc_report1 = "metrics/{lane}_r1_fastqc_raw_metrics.html",
        fastqc_report2 = "metrics/{lane}_r2_fastqc_raw_metrics.html"
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

# For each lane, generate a separate ex_namesamples_{lane} rule
# Replace default index names with experiment specific sample names as defined in ex_samples.csv for each lane
for lane in lanes:
    rule_name = f"ex_namesamples_{lane}"

    rule:
        name: rule_name
        input:
            r1start = config["codec_r1start_path"],
            r1end   = config["codec_r1end_path"],
            r2start = config["codec_r2start_path"],
            r2end   = config["codec_r2end_path"],
            mapping = config["ex_samples_path"]
        output:
            r1start_out = f"tmp/reference/{lane}_r1start.fasta",
            r1end_out   = f"tmp/reference/{lane}_r1end.fasta",
            r2start_out = f"tmp/reference/{lane}_r2start.fasta",
            r2end_out   = f"tmp/reference/{lane}_r2end.fasta"
        params:
            lane = lane
        script:
            "../scripts/samplenames.py"

# For each lane, generate a separate ex_demux_{lane} rule
# Removes first 3bp of R1 and R2 to read name as 6 base UMI. Demultiplexes using R1 and R2 5' sample indices (both must agree). Trims 5' sample indices. 
for lane in lanes:
    #Determine which samples are to be generated from the lane
    samples = pd.read_csv(config["ex_samples_path"])[pd.read_csv(config["ex_samples_path"])["lane"] == lane]["ex_sample"].tolist()
    demuxed_r1 = [f"tmp/{s}_r1_raw.fastq.gz" for s in samples]
    demuxed_r2 = [f"tmp/{s}_r2_raw.fastq.gz" for s in samples]
    #Generate 1 rule per lane
    rule_name = f"ex_demux_{lane}"

    rule:
        name: rule_name
        input:
            fastq1 = ex_raw_fastq1[lane],
            fastq2 = ex_raw_fastq2[lane],
            r1_start = f"tmp/reference/{lane}_r1start.fasta",
            r2_start = f"tmp/reference/{lane}_r2start.fasta"
        output:
            demuxed_r1 = demuxed_r1,
            demuxed_r2 = demuxed_r2,
            json = f"metrics/{lane}_demux_metrics.json"
        threads:
            config["ncores"]
        shell:
            f"""
            cutadapt \
              -j {{threads}} \
              --no-indels \
              -e 2 \
              -g ^file:{{input.r1_start}} \
              -G ^file:{{input.r2_start}} \
              --cut 3 \
              -U 3 \
              --pair-adapters \
              --rename='{{{{id}}}}:{{{{r1.cut_prefix}}}}{{{{r2.cut_prefix}}}}' \
              -o tmp/{{{{name}}}}_r1_raw.fastq.gz \
              -p tmp/{{{{name}}}}_r2_raw.fastq.gz \
              {{input.fastq1}} {{input.fastq2}} \
              --json={{output.json}}
            """

# Identifies and trims 3' sample indices from R1 and R2 when present
rule ex_trim:
    input:
        r1 = "tmp/{ex_sample}_r1_raw.fastq.gz",
        r2 = "tmp/{ex_sample}_r2_raw.fastq.gz",
        r1_end = lambda wildcards: f"tmp/reference/{ex_sample_to_lane[wildcards.ex_sample]}_r1end.fasta",
        r2_end = lambda wildcards: f"tmp/reference/{ex_sample_to_lane[wildcards.ex_sample]}_r2end.fasta"
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
        json = "metrics/{lane}_demux_metrics.json"
    output:
        readcounts = "metrics/{lane}_sample_readcounts_metrics.txt"
    params:
        fasta = config['r1start'],
        used = config['ex_samples']
    script:
        "../scripts/rawreadcounts.py"

# Custom python script to assess how many unused indices were detected from other experiments (similar metrics to rawreadcounts). This should always be 0. 
rule ex_batchcontamination_metrics:
    input:
        json = "metrics/{lane}_demux_metrics.json"
    output:
        contamination = "metrics/{lane}_batchcontamination_metrics.txt"
    params:
        fasta = config['r1start'],
        used = config['ex_samples']
    script:
        "../scripts/batchcontamination.py"