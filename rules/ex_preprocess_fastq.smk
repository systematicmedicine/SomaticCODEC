"""
--- ex_preprocess_fastq.smk ---

Rules for preprocssessing FASTQ files for experimental samples

Input: Raw FASTQ files, generated from Illumina sequencing of CODEC libraries, prepared from experimental samples
Output: Fully processed FASTQ files ready for alignment 

Authors: 
    - James Phie
    - Cameron Fraser

"""

import scripts.get_metadata as md

"""
Generate adapter FASTA files for demultiplexing and trimming
""" 
rule ex_generate_adapter_fastas:
    input:
        ex_lanes = config["ex_lanes_path"],
        ex_samples = config["ex_samples_path"],
        ex_adapters = config["ex_adapters_path"]
    output:
        adapter_fasta_outputs = expand(
            "tmp/{ex_lane}/{ex_lane}_{region}.fasta",
            ex_lane = md.get_ex_lane_ids(config),
            region = ["r1_start", "r1_end", "r2_start", "r2_end"]
        )
    log:
        "logs/ex_generate_adapter_fastas.log"
    benchmark:
        "logs/ex_generate_adapter_fastas.benchmark.txt"
    script:
        "../scripts/ex_generate_adapter_fastas.py"


"""
Moves the read pair UMI to readname
    - Cut 3bp from the start of the read 1 and read 2 sequence
    - Append read 1 3bp UMI sequence to the readname of read 1 and read 2
    - Append read 2 3bp UMI sequence after read 1 UMI in read 1 and read 2
""" 
rule ex_extract_umis:
    input:
        ex_lanes = config["ex_lanes_path"],
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1]
    output:
        fastq1 = temp("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz"),
        fastq2 = temp("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz")
    log:
        "logs/{ex_lane}/ex_extract_umis.log"
    benchmark:
        "logs/{ex_lane}/ex_extract_umis.benchmark.txt"
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


"""
Demultiplex each lane FASTQ into sample FASTQs
    - Use the 18bp sample indices to match reads to samples
    - Allowed error of 2 edit distance
""" 
rule ex_demux:
    input:
        ex_lanes = config["ex_lanes_path"],
        ex_samples = config["ex_samples_path"],
        fastq1 = expand("tmp/{ex_lane}/{ex_lane}_r1_umi_extracted.fastq.gz", ex_lane = md.get_ex_lane_ids(config)),
        fastq2 = expand("tmp/{ex_lane}/{ex_lane}_r2_umi_extracted.fastq.gz", ex_lane = md.get_ex_lane_ids(config)),
        r1_start = expand("tmp/{ex_lane}/{ex_lane}_r1_start.fasta", ex_lane = md.get_ex_lane_ids(config)),
        r2_start = expand("tmp/{ex_lane}/{ex_lane}_r2_start.fasta", ex_lane = md.get_ex_lane_ids(config))
    output:
        demuxed_r1 = temp(expand("tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz", ex_sample = md.get_ex_sample_ids(config))),
        demuxed_r2 = temp(expand("tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz", ex_sample = md.get_ex_sample_ids(config))),
        json = expand("metrics/{ex_lane}/{ex_lane}_demux_metrics.json", ex_lane = md.get_ex_lane_ids(config))
    log:
        "logs/ex_demux.log"
    benchmark:
        "logs/ex_demux.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    script:
        "../scripts/ex_demux.py"


"""
Trim reads so that only inserts are remaining
    1. Trim 5' adapter sequences
    2. Trim 3' adapter sequences
    3. Trim 3 additional bases from the 5' end (to account for short adapter sequences/A-tailing remnants)
    4. Trim 8 additional bases from the 3' end (to account for short adapter sequences/A-tailing remnants)
    5. Remove any bases with a Q score of <20 from the 3' end
"""
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
        r1_start = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r1_start"],
        r1_end = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r1_end"],
        r2_start = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r2_start"],
        r2_end = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r2_end"]
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
    # Mean per read base quality >=Q36
    # Number of N bases <=3
rule ex_filter:
    input: 
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz"),
        r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"),
        intermediate_r1 = temp("tmp/{ex_sample}/{ex_sample}_r1_filter_tmp.fastq.gz"),
        intermediate_r2 = temp("tmp/{ex_sample}/{ex_sample}_r2_filter_tmp.fastq.gz"),
        json_length = "metrics/{ex_sample}/{ex_sample}_filter_readlength_metrics.json",
        json_meanquality = "metrics/{ex_sample}/{ex_sample}_filter_meanquality_metrics.json",
    log:
        "logs/{ex_sample}/ex_filter.log"
    benchmark:
        "logs/{ex_sample}/ex_filter.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:  
        """
        fastp \
          -i {input.r1} \
          -I {input.r2} \
          -o {output.intermediate_r1} \
          -O {output.intermediate_r2} \
          --length_required 70 \
          --disable_quality_filtering \
          --n_base_limit 49 \
          --disable_adapter_trimming \
          --thread {threads} \
          --html /dev/null \
          --json {output.json_length} 2>> {log}

        fastp \
          -i {output.intermediate_r1} \
          -I {output.intermediate_r2} \
          -o {output.r1} \
          -O {output.r2} \
          --average_qual 36 \
          --n_base_limit 3 \
          --disable_adapter_trimming \
          --thread {threads} \
          --html /dev/null \
          --json {output.json_meanquality} 2>> {log}
        """

