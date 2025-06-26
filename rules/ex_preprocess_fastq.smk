"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Author: James Phie

"""
# Create lists of raw experimental FASTQ files and check that they are unique
ex_raw_r1_list = ex_lanes.set_index("ex_lane")["fastq1"].to_dict()
ex_raw_r2_list = ex_lanes.set_index("ex_lane")["fastq2"].to_dict()

# Creates dictionaries to lookup between ex_lane and ex_sample
ex_sample_to_lane = ex_samples.set_index("ex_sample")["lane"].to_dict()
ex_lane_to_sample = ex_samples.groupby("lane")["ex_sample"].apply(list).to_dict() #Currently broken in ex_preprocess_fastq, but used in ex_metrics

# Generate adapter fasta files for demultiplexing and trimming using adapter sequences in ex_adapters.csv
rule ex_generate_adapter_fastas:
    input:
        adapters=config["ex_adapters_path"]
    params:
        samples = ex_samples
    output:
        adapter_fasta_outputs = expand("tmp/adapter_fastas/{ex_lane}_{region}.fasta", ex_lane=ex_lanes["ex_lane"].tolist(), region=["r1_start", "r1_end", "r2_start", "r2_end"])
    script:
        "../scripts/generatefastas.py"

# Moves the read pair umi to readname
    # Cut 3bp from the start of the read 1 and read 2 sequence
    # Append read 1 3bp umi sequence to the readname of read 1 and read 2
    # Append read 2 3bp umi sequence after read 1 umi in read 1 and read 2
rule ex_extract_umis:
    input:
        fastq1 = lambda wildcards: ex_raw_r1_list[wildcards.ex_lane],
        fastq2 = lambda wildcards: ex_raw_r2_list[wildcards.ex_lane]
    output:
        fastq1 = temp("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"),
        fastq2 = temp("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz")
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
          -j {threads} \
          --cut 3 \
          -U 3 \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o {output.fastq1} \
          -p {output.fastq2} \
          {input.fastq1} {input.fastq2} \
        """

# Demultiplex each lane (fastq pair) into samples
    # Use the 18bp sample indices to match to indicated samples, with an allowed error of 2 edit distance
rule ex_demux:
    input:
        fastq1 = "tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz",
        fastq2 = "tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz",
        r1_start = "tmp/adapter_fastas/{ex_lane}_r1_start.fasta",
        r2_start = "tmp/adapter_fastas/{ex_lane}_r2_start.fasta"
    output:
        json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json",
        #demuxed_r1 = lambda wc: expand("tmp/{lane_sample}_r1_demux.fastq.gz", lane_sample=ex_lane_to_sample[wc.ex_lane]),
        #demuxed_r2 = lambda wc: expand("tmp/{lane_sample}_r2_demux.fastq.gz", lane_sample=ex_lane_to_sample[wc.ex_lane])
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
          -j {threads} \
          --no-indels \
          -e 2 \
          -g ^file:{input.r1_start} \
          -G ^file:{input.r2_start} \
          --pair-adapters \
          -o tmp/{{name}}_r1_demux.fastq.gz \
          -p tmp/{{name}}_r2_demux.fastq.gz \
          {input.fastq1} {input.fastq2} \
          --json={output.json} \
          --action=none \
        """

# Trim all demultiplexed reads so that only inserts are remaining
    # Trim 5' adapter sequences
    # Trim 3' adapter sequences
    # Trim 3 additional bases from the 5' end (to account for short adapter sequences/A-tailing remnants)
    # Trim 8 additional bases from the 3' end (to account for short adapter sequences/A-tailing remnants)
    # Remove any bases with a Q score of <20 from the 3' end
rule ex_trim:
    input:
        json = lambda wildcards: f"metrics/{ex_sample_to_lane[wildcards.ex_sample]}/{ex_sample_to_lane[wildcards.ex_sample]}_demux_metrics.json",
        r1_start = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r1_start.fasta",
        r2_start = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r2_start.fasta",
        r1_end = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r1_end.fasta",
        r2_end = lambda wildcards: f"tmp/adapter_fastas/{ex_sample_to_lane[wildcards.ex_sample]}_r2_end.fasta"
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_trim_metrics.json"
    params:
        r1 = "tmp/{ex_sample}_r1_demux.fastq.gz", # Moved to params as snakemake is not tracking demux inputs
        r2 = "tmp/{ex_sample}_r2_demux.fastq.gz", # Moved to params as snakemake is not tracking demux inputs
        intermediate_r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim_adapters.fastq.gz"),
        intermediate_r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim_adapters.fastq.gz")
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
          -j {threads} \
          -e 1 \
          -O 7 \
          -g ^file:{input.r1_start} \
          -G ^file:{input.r2_start} \
          -a file:{input.r1_end} \
          -A file:{input.r2_end} \
          -o {params.intermediate_r1} \
          -p {params.intermediate_r2} \
          {params.r1} {params.r2} \
          --json={output.json}

        cutadapt \
          -j {threads} \
          -u 3 \
          -U 3 \
          -u -8 \
          -U -8 \
          --quality-cutoff 20 \
          -o {output.r1} \
          -p {output.r2} \
          {params.intermediate_r1} \
          {params.intermediate_r2} \
        """

# Filter inserts (trimmed sequences)
    # Insert size >70bp
rule ex_filter:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"),
        json = "metrics/{ex_sample}/{ex_sample}_filter_metrics.json",
    threads:
        max(1, os.cpu_count() // 4)
    shell:  
        """
        cutadapt \
        -j {threads} \
        --minimum-length 70 \
        -o {output.r1} \
        -p {output.r2} \
        {input.r1} {input.r2} \
        --json={output.json}
        """

