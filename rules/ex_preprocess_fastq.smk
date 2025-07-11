"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Author: James Phie

"""
# Generate adapter fasta files for demultiplexing and trimming using adapter sequences in ex_adapters.csv
rule ex_generate_adapter_fastas:
    params:
        samples = ex_samples,
        adapters = ex_adapters
    output:
        adapter_fasta_outputs = expand("tmp/{ex_lane}/{ex_lane}_{region}.fasta", ex_lane=ex_lanes["ex_lane"].tolist(), region=["r1_start", "r1_end", "r2_start", "r2_end"])
    script:
        "../scripts/ex_generate_adapter_fastas.py"

# Moves the read pair umi to readname
    # Cut 3bp from the start of the read 1 and read 2 sequence
    # Append read 1 3bp umi sequence to the readname of read 1 and read 2
    # Append read 2 3bp umi sequence after read 1 umi in read 1 and read 2
rule ex_extract_umis:
    input:
        fastq1 = lambda wildcards: ex_lanes.loc[ex_lanes["ex_lane"] == wildcards.ex_lane, "fastq1"].values[0],
        fastq2 = lambda wildcards: ex_lanes.loc[ex_lanes["ex_lane"] == wildcards.ex_lane, "fastq2"].values[0],
    output:
        fastq1 = temp("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"),
        fastq2 = temp("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz")
    log:
        "logs/{ex_lane}/ex_extract_umis.log"
    benchmark:
        "logs/{ex_lane}/ex_extract_umis.txt"
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
          {input.fastq1} {input.fastq2} 2>> {log}
        """

# Demultiplex each lane (fastq pair) into samples
    # Use the 18bp sample indices to match to indicated samples, with an allowed error of 2 edit distance
rule ex_demux:
    input:
        fastq1 = expand("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz", ex_lane=ex_lanes["ex_lane"].tolist()),
        fastq2 = expand("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz", ex_lane=ex_lanes["ex_lane"].tolist()),
        r1_start = expand("tmp/{ex_lane}/{ex_lane}_r1_start.fasta", ex_lane=ex_lanes["ex_lane"].tolist()),
        r2_start = expand("tmp/{ex_lane}/{ex_lane}_r2_start.fasta", ex_lane=ex_lanes["ex_lane"].tolist())
    output:
        demuxed_r1 = temp(expand("tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz", ex_sample=ex_samples["ex_sample"].tolist())),
        demuxed_r2 = temp(expand("tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz", ex_sample=ex_samples["ex_sample"].tolist())),
        json = expand("metrics/{ex_lane}/{ex_lane}_demux_metrics.json", ex_lane=ex_lanes["ex_lane"].tolist())
    params:
        samples = ex_samples,
        lanes = ex_lanes
    threads:
        max(1, os.cpu_count() // 4)
    script:
        "../scripts/ex_demultiplex_all_lanes.py"


# Trim all demultiplexed reads so that only inserts are remaining
    # Trim 5' adapter sequences
    # Trim 3' adapter sequences
    # Trim 3 additional bases from the 5' end (to account for short adapter sequences/A-tailing remnants)
    # Trim 8 additional bases from the 3' end (to account for short adapter sequences/A-tailing remnants)
    # Remove any bases with a Q score of <20 from the 3' end
rule ex_trim:
    input:
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz"),
        trim5primejson = "metrics/{ex_sample}/{ex_sample}_trim_5prime_metrics.json",
        r1_trim3primejson = "metrics/{ex_sample}/{ex_sample}_r1_trim_3prime_metrics.json",
        r2_trim3primejson = "metrics/{ex_sample}/{ex_sample}_r2_trim_3prime_metrics.json",
        intermediate_r1_1 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim_adapters.fastq.gz"),
        intermediate_r2_1 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim_adapters.fastq.gz"),
        intermediate_r1_2 = temp("tmp/{ex_sample}/{ex_sample}_r1_trim_adapters2.fastq.gz"),
        intermediate_r2_2 = temp("tmp/{ex_sample}/{ex_sample}_r2_trim_adapters2.fastq.gz")
    params:
        r1_start = lambda wildcards: ex_samples.loc[ex_samples["ex_sample"] == wildcards.ex_sample, "r1_start"].values[0].strip(),
        r2_start = lambda wildcards: ex_samples.loc[ex_samples["ex_sample"] == wildcards.ex_sample, "r2_start"].values[0].strip(),
        r1_end = lambda wildcards: ex_samples.loc[ex_samples["ex_sample"] == wildcards.ex_sample, "r1_end"].values[0].strip(),
        r2_end = lambda wildcards: ex_samples.loc[ex_samples["ex_sample"] == wildcards.ex_sample, "r2_end"].values[0].strip()
    log:
        "logs/{ex_sample}/ex_trim.log"
    benchmark:
        "logs/{ex_sample}/ex_trim.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        cutadapt \
          -j {threads} \
          -e 2 \
          -g ^{params.r1_start} \
          -G ^{params.r2_start} \
          -o {output.intermediate_r1_1} \
          -p {output.intermediate_r2_1} \
          {input.r1} {input.r2} \
          --json={output.trim5primejson} 2>> {log}

        cutadapt \
          -j {threads} \
          -e 2 \
          --overlap 8 \
          -b {params.r1_end} \
          -o {output.intermediate_r1_2} \
          {output.intermediate_r1_1} \
          --json={output.r1_trim3primejson} 2>> {log}

        cutadapt \
          -j {threads} \
          -e 2 \
          --overlap 8 \
          -b {params.r2_end} \
          -o {output.intermediate_r2_2} \
          {output.intermediate_r2_1} \
          --json={output.r2_trim3primejson} 2>> {log}

        cutadapt \
          -j {threads} \
          -u 3 \
          -U 3 \
          -u -9 \
          -U -9 \
          --quality-cutoff 20 \
          -o {output.r1} \
          -p {output.r2} \
          {output.intermediate_r1_2} {output.intermediate_r2_2} 2>> {log}
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
        json = "metrics/{ex_sample}/{ex_sample}_filter_metrics.json"
    log:
        "logs/{ex_sample}/ex_filter.log"
    benchmark:
        "logs/{ex_sample}/ex_filter.benchmark.txt"
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
        --json={output.json} 2>> {log}
        """

