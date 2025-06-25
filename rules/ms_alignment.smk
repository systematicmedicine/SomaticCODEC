"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample processed reads

Input: Processed ms FASTQ files
Outputs: 
    - ms raw alignment BAM
    - Metrics files

Author: Joshua Johnstone

"""

# Aligns reads to reference
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
        bam = "tmp/{ms_sample}/{ms_sample}_aligned.bam" # Change to temp once pipeline development is complete
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        # Get lane information from headers
        lane=$(zcat {input.r1_processed} | head -n1 | cut -d ':' -f4)

        # Define read groups (sample ID, sample name, library, platform, platform unit)
        read_group="@RG\\tID:{wildcards.ms_sample}_${{lane}}\\tSM:{wildcards.ms_sample}\\tLB:{wildcards.ms_sample}_lib\\tPL:ILLUMINA\\tPU:{wildcards.ms_sample}.${{lane}}"

        # Add read groups and align
        bwa-mem2 mem \
            -t {threads} \
            -R "$read_group" \
            {input.ref} \
            {input.r1_processed} \
            {input.r2_processed} | \
        samtools view -bS - > {output.bam}
        """

# Sorts bam by coordinate
rule ms_sort_bam:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_aligned.bam"
    output:
        bam_sorted =  temp("tmp/{ms_sample}/{ms_sample}_sorted.bam")
    threads: 
        max(1, os.cpu_count() // 8)
    shell:
        "samtools sort -@ {threads} -o {output.bam_sorted} {input.bam}"

# Marks duplicate reads in bam file
rule ms_mark_duplicates:
    input:
        bam_sorted = "tmp/{ms_sample}/{ms_sample}_sorted.bam"
    output:
        bam_markdup = temp("tmp/{ms_sample}/{ms_sample}_markdup.bam"),
        bai_markdup = temp("tmp/{ms_sample}/{ms_sample}_markdup.bai"),
        dup_metrics = "metrics/{ms_sample}/{ms_sample}_markdup_metrics.txt"
    shell:
        """
        picard MarkDuplicates \
        I={input.bam_sorted} \
        O={output.bam_markdup} \
        M={output.dup_metrics} \
        CREATE_INDEX=true
        """
