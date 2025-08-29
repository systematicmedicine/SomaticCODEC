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
        ref = config["files"]['reference'],
        amb = config["files"]['reference'] + ".amb",
        ann = config["files"]['reference'] + ".ann",
        bwt = config["files"]['reference'] + ".bwt.2bit.64",
        pac = config["files"]['reference'] + ".pac",
        sa = config["files"]['reference'] + ".0123",
        r1_processed = "tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz",
        r2_processed = "tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_raw_map.bam"),
        intermediate_sam = temp("tmp/{ms_sample}/{ms_sample}_raw_map.sam")
    params:
        band_width = config["rules"]["ms_map"]["band_width"],
        clipping_penalty = config["rules"]["ms_map"]["clipping_penalty"],
        gap_extension_penalty = config["rules"]["ms_map"]["gap_extension_penalty"],
        gap_open_penalty = config["rules"]["ms_map"]["gap_open_penalty"],
        matching_score = config["rules"]["ms_map"]["matching_score"],
        mem_max_occurances = config["rules"]["ms_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["rules"]["ms_map"]["min_alignment_score_thresh"],
        min_seed_length = config["rules"]["ms_map"]["min_seed_length"],
        mismatch_penalty = config["rules"]["ms_map"]["mismatch_penalty"],
        reseed_factor = config["rules"]["ms_map"]["reseed_factor"],
        unpaired_read_penalty = config["rules"]["ms_map"]["unpaired_read_penalty"],
        z_dropoff = config["rules"]["ms_map"]["z_dropoff"]        
    log:
        "logs/{ms_sample}/ms_raw_alignment.log"
    benchmark:
        "logs/{ms_sample}/ms_raw_alignment.benchmark.txt"
    threads: 
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["heavy"]
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
        "logs/{ms_sample}/ms_annotate_map.log"
    benchmark:
        "logs/{ms_sample}/ms_annotate_map.benchmark.txt"
    threads:
        config["resources"]["threads"]["moderate"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp AddOrReplaceReadGroups \
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


# Removes duplicate reads based on alignment and UMIs
rule ms_remove_duplicates:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam",
        bai = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam.bai"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_deduped_map.bam"),
        bai = temp("tmp/{ms_sample}/{ms_sample}_deduped_map.bam.bai"),
        dedup_metrics = "metrics/{ms_sample}/{ms_sample}_dedup_metrics.txt",
        intermediate_unsorted = temp("tmp/{ms_sample}/{ms_sample}_deduped_map_unsorted.bam")
    log:
        "logs/{ms_sample}/ms_remove_duplicates.log"
    benchmark:
        "logs/{ms_sample}/ms_remove_duplicates.benchmark.txt"
    threads:
        config["resources"]["threads"]["moderate"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        umi_tools dedup \
            --extract-umi-method=read_id \
            --umi-separator=":" \
            --paired \
            --stdin {input.bam} \
            --stdout {output.intermediate_unsorted} \
            --log={output.dedup_metrics} 2>> {log}

        samtools sort -@ {threads} -o {output.bam} {output.intermediate_unsorted} 2>> {log}

        samtools index {output.bam} 2>> {log}
        """