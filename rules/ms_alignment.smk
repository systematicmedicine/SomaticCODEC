"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample processed reads

Input: 
    - Processed ms FASTQ files
Outputs: 
    - BAM with reads aligned to GCRh38, sorted and duplicates removed

Author: Joshua Johnstone

"""

# Aligns reads to reference genome
rule ms_map:
    input: 
        ref = config['GRCh38_path'],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config['GRCh38_path'] + ".0123",
        r1_processed = "tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz",
        r2_processed = "tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_raw_map.bam"),
        intermediate_sam = temp("tmp/{ms_sample}/{ms_sample}_raw_map.sam")
    params:
        band_width = config["ms_map"]["band_width"],
        clipping_penalty = config["ms_map"]["clipping_penalty"],
        gap_extension_penalty = config["ms_map"]["gap_extension_penalty"],
        gap_open_penalty = config["ms_map"]["gap_open_penalty"],
        matching_score = config["ms_map"]["matching_score"],
        mem_max_occurances = config["ms_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["ms_map"]["min_alignment_score_thresh"],
        min_seed_length = config["ms_map"]["min_seed_length"],
        mismatch_penalty = config["ms_map"]["mismatch_penalty"],
        reseed_factor = config["ms_map"]["reseed_factor"],
        unpaired_read_penalty = config["ms_map"]["unpaired_read_penalty"],
        z_dropoff = config["ms_map"]["z_dropoff"]        
    log:
        "logs/{ms_sample}/ms_raw_alignment.log"
    benchmark:
        "logs/{ms_sample}/ms_raw_alignment.benchmark.txt"
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem \
        -t {threads} \
        -k {params.min_seed_length} \
        -w {params.band_width} \
        -d {params.z_dropoff} \
        -r {params.reseed_factor} \
        -c {params.mem_max_occurances} \
        -A {params.matching_score} \
        -B {params.mismatch_penalty} \
        -O {params.gap_open_penalty} \
        -E {params.gap_extension_penalty} \
        -L {params.clipping_penalty} \
        -U {params.unpaired_read_penalty} \
        -T {params.min_alignment_score_thresh} \
        {input.ref} {input.r1_processed} {input.r2_processed} > {output.intermediate_sam} 2>> {log}

        samtools view -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """

# Adds read group information to aligned reads
rule ms_annotate_map:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_raw_map.bam"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_read_group_map.bam"),
        bai = temp("tmp/{ms_sample}/{ms_sample}_read_group_map.bam.bai"),
        intermediate_unsorted = temp("tmp/{ms_sample}/{ms_sample}_read_group_map_unsorted.bam")
    log:
        "logs/{ms_sample}/ms_add_read_groups.log"
    benchmark:
        "logs/{ms_sample}/ms_add_read_groups.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 8)
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.intermediate_unsorted} \
            RGID={wildcards.ms_sample} \
            RGLB={wildcards.ms_sample}_lib \
            RGPL=ILLUMINA \
            RGPU={wildcards.ms_sample} \
            RGSM={wildcards.ms_sample} 2>> {log}

        samtools sort -@ {threads} -o {output.bam} {output.intermediate_unsorted} 2>> {log}

        samtools index {output.bam} 2>> {log}
        """
