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
        r1_processed = "tmp/{ms_sample}/{ms_sample}_processed_r1.fastq.gz",
        r2_processed = "tmp/{ms_sample}/{ms_sample}_processed_r2.fastq.gz"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_aligned.bam")
    threads: max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem \
            -t {threads} \
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
    threads: max(1, os.cpu_count() // 8)
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

# Generates alignment metrics
rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_markdup.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt",
        insert_metrics = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"
    shell:
        """
        # Generate alignment stats
        samtools stats {input.bam} > {output.stats}

        # Collect insert size metrics
        picard CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist}
            
        """ 