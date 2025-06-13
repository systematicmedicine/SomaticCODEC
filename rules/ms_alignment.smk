"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample trimmed and filtered reads

Input: Processed ms FASTQ files
Outputs: 
    - ms raw alignment BAM
    - Metrics files

Author: Joshua Johnstone

"""

# Aligns reads to reference
rule raw_alignment:
    input: 
        ref = ref,
        r1_processed = "tmp/data/{ms_sample}_processed_r1.fastq.gz",
        r2_processed = "tmp/data/{ms_sample}_processed_r2.fastq.gz"
    output:
        bam = temp("tmp/results/{ms_sample}_aligned.bam")
    threads: 32
    shell:
        """
        bwa-mem2 mem -R "@RG\\tID:{wildcards.ms_sample}\\tSM:{wildcards.ms_sample}\\tPL:ILLUMINA" \
            -t {threads} \
            {input.ref} \
            {input.r1_processed} \
            {input.r2_processed} | \
        samtools view -bS - > {output.bam}

        """

# Sorts bam by coordinate
rule sort_bam:
    input:
        bam = "tmp/results/{ms_sample}_aligned.bam"
    output:
        bam_sorted =  temp("tmp/results/{ms_sample}_sorted.bam")
    threads: 8
    shell:
        "samtools sort -@ {threads} -o {output.bam_sorted} {input.bam}"

rule mark_duplicates:
    input:
        bam_sorted = "tmp/results/{ms_sample}_sorted.bam"
    output:
        bam_markdup = "tmp/results/{ms_sample}_markdup.bam",
        bai_markdup = "tmp/results/{ms_sample}_markdup.bai",
        dup_metrics = "tmp/metrics/markdup/{ms_sample}_markdup_metrics.txt"
    shell:
        """
        picard MarkDuplicates \
        I={input.bam_sorted} \
        O={output.bam_markdup} \
        M={output.dup_metrics} \
        CREATE_INDEX=true

        """

# Generates alignment metrics
rule alignment_metrics:
    input:
        bam = "tmp/results/{ms_sample}_markdup.bam"
    output:
        stats = "tmp/metrics/alignment/{ms_sample}_samtools_stats.txt",
        insert_metrics = "tmp/metrics/alignment/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "tmp/metrics/alignment/{ms_sample}_insert_size_histogram.pdf"
    shell:
        """
        # Generate alignment stats
        samtools stats {input.bam} > {output.stats}

        # Collect insert size metrics
        # M = 0.5 means 50% of reads must fall within the insert size peak to generate metrics
        picard CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} \
            M=0.5
            
        """ 