"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample processed reads

Input: 
    - Processed ms FASTQ files
Outputs: 
    - BAM with reads aligned to GCRh38, sorted and duplicates marked

Author: Joshua Johnstone

"""

# Aligns reads to reference genome
rule ms_raw_alignment:
    input: 
        ref = config['GRCh38_path'],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config['GRCh38_path'] + ".0123",
        r1_processed = "tmp/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz",
        r2_processed = "tmp/{ms_sample}/{ms_sample}_trimfilter_r2.fastq.gz"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_raw_map.bam")
    params:
        intermediate_sam = temp("tmp/{ms_sample}/{ms_sample}_raw_intermediate.sam")
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem \
            -t {threads} \
            {input.ref} \
            {input.r1_processed} \
            {input.r2_processed} > {params.intermediate_sam}

        samtools view -bS {params.intermediate_sam} > {output.bam}
        """

# Adds read group information to aligned reads
rule ms_add_read_groups:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_raw_map.bam",
        r1_processed = "tmp/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_read_group_map.bam")
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam} \
            RGID={wildcards.ms_sample} \
            RGLB={wildcards.ms_sample}_lib \
            RGPL=ILLUMINA \
            RGPU={wildcards.ms_sample} \
            RGSM={wildcards.ms_sample}
        """

# Sorts bam by coordinate
rule ms_sort_bam:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam"
    output:
        bam_sorted =  temp("tmp/{ms_sample}/{ms_sample}_sorted_map.bam")
    threads: 
        max(1, os.cpu_count() // 8)
    shell:
        "samtools sort -@ {threads} -o {output.bam_sorted} {input.bam}"

# Marks duplicate reads in bam file
rule ms_mark_duplicates:
    input:
        bam_sorted = "tmp/{ms_sample}/{ms_sample}_sorted_map.bam"
    output:
        bam_markdup = temp("tmp/{ms_sample}/{ms_sample}_markdup_map.bam"),
        bai_markdup = temp("tmp/{ms_sample}/{ms_sample}_markdup_map.bai"),
        dup_metrics = "metrics/{ms_sample}/{ms_sample}_markdup_metrics.txt"
    shell:
        """
        picard MarkDuplicates \
        I={input.bam_sorted} \
        O={output.bam_markdup} \
        M={output.dup_metrics} \
        CREATE_INDEX=true
        """
