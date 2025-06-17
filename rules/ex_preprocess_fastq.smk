"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Author: James Phie

"""
# Create lists of raw experimental FASTQ files and check that they are unique
ex_raw_r1_list = pd.read_csv(config["ex_samples_path"]).drop_duplicates("ex_lane").set_index("ex_lane")["fastq1"].to_dict()
ex_raw_r2_list = pd.read_csv(config["ex_samples_path"]).drop_duplicates("ex_lane").set_index("ex_lane")["fastq2"].to_dict()
assert all(pd.read_csv(config["ex_samples_path"]).groupby("ex_lane")[col].nunique().eq(1).all() for col in ["fastq1", "fastq2"]), "Inconsistent FASTQ files per lane"

#Creates mapping between lane and ex_sample to determine which fasta file should be applied to each ex_sample during trimming
ex_sample_to_lane = pd.read_csv(config["ex_samples_path"]).set_index("ex_sample")["ex_lane"].to_dict()

# FastQC on raw fastq files (before demultiplexing or any processing)
rule ex_fastqcraw_metrics:
    input:
        fastq1 = lambda wildcards: ex_raw_r1_list[wildcards.lane],
        fastq2 = lambda wildcards: ex_raw_r2_list[wildcards.lane]
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

#Generate adapter fasta files for demultiplexing and trimming using adapter sequences in ex_adapters.csv
rule ex_generate_adapter_fastas:
    input:
        samples=config["ex_samples_path"],
        adapters=config["ex_adapters_path"]
    output:
        adapter_fasta_outputs = expand("tmp/adapter_fastas/{lane}_{region}.fasta", lane=ex_lanes, region=["r1start", "r1end", "r2start", "r2end"])
    script:
        "../scripts/generatefastas.py"

# For each lane, generate a separate ex_demux_{lane} rule
# Removes first 3bp of R1 and R2 to read name as 6 base UMI. 
# Demultiplexes using R1 and R2 5' sample indices (both must agree). 
# Trims 5' sample indices used for demultiplexing. 
for lane in lanes:
    #Determine which samples are present in the lane
    samples = pd.read_csv(config["ex_samples_path"])[pd.read_csv(config["ex_samples_path"])["lane"] == lane]["ex_sample"].tolist()
    #Create list of file outputs based on samples present in the lane
    demuxed_r1 = [f"tmp/{s}_r1_trim5.fastq.gz" for s in samples]
    demuxed_r2 = [f"tmp/{s}_r2_trim5.fastq.gz" for s in samples]
    #Generate 1 rule per lane
    rule_name = f"ex_demux_{lane}"

    rule:
        name: rule_name
        input:
            fastq1 = ex_raw_r1_list[lane],
            fastq2 = ex_raw_r2_list[lane],
            r1_start = f"tmp/adapter_fastas/{lane}_r1start.fasta",
            r2_start = f"tmp/adapter_fastas/{lane}_r2start.fasta"
        output:
            demuxed_r1 = demuxed_r1,
            demuxed_r2 = demuxed_r2,
            json = f"metrics/{lane}_demux_metrics.json"
        threads:
            max(1, os.cpu_count()//4)
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
              -o tmp/{{{{name}}}}_r1_trim5.fastq.gz \
              -p tmp/{{{{name}}}}_r2_trim5.fastq.gz \
              {{input.fastq1}} {{input.fastq2}} \
              --json={{output.json}}
            """

# Identifies and trims 3' sample indices from R1 and R2 when present
rule ex_trim_3prime_indices:
    input:
        r1 = "tmp/{ex_sample}_r1_trim5.fastq.gz",
        r2 = "tmp/{ex_sample}_r2_trim5.fastq.gz",
        r1_end = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r1end.fasta",
        r2_end = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r2end.fasta"
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim5&3.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim5&3.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_trim_metrics.json"
    threads:
        max(1, os.cpu_count()//4)
    shell:
        """
        #Trim 3' indices/adapters
        cutadapt \
          -j {threads} \
          -e 1 \
          -O 7 \
          -a file:{input.r1_end} \
          -A file:{input.r2_end} \
          -o {output.r1} \
          -p {output.r2} \
          {input.r1} {input.r2} \
          --json={output.json}
        """

#Trim additional bases from 5' and 3' ends to remove remnant adapter sequences (e.g. <7 bases not identified in 3' trimming) and A/T bases from A-tailing
rule ex_trim_remnants:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim5&3.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim5&3.fastq.gz", 
    output:
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz", 
        """
        cutadapt \
          -j {threads} \
          -u 3 \
          -U 3 \
          -u -8 \
          -U -8 \
          -o {output.r1} \
          -p {output.r2} \
          {input.r1} {input.r2} \
          --json={output.json}
        """

# Filter trimmed sequences for insert size <70bp and mean quality score >20
rule ex_filter:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_filter_metrics.json"
    threads:
        max(1, os.cpu_count()//4)
    shell:  
        """
        cutadapt \
        -j {threads} \
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
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.html"
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
        fasta = lambda wildcards: f"tmp/adapter_fastas/{wildcards.lane}_r1start.fasta",
        used = config['ex_samples_path']
    script:
        "../scripts/rawreadcounts.py"
