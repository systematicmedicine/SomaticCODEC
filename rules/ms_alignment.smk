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
        r1_processed = "tmp/data/{sample}_processed_r1.fastq.gz",
        r2_processed = "tmp/data/{sample}_processed_r2.fastq.gz"
    output:
        bam = "tmp/results/{sample}_aligned.bam"
    threads: 32
    shell:
        """
        bwa-mem2 mem -R "@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            -t {threads} \
            {input.ref} \
            {input.r1_processed} \
            {input.r2_processed} | \
        samtools view -bS - > {output.bam}

        """

# Sorts bam by coordinate
rule sort_bam:
    input:
        bam = "tmp/results/{sample}_aligned.bam"
    output:
        bam_sorted =  "tmp/results/{sample}_sorted.bam"
    threads: 8
    shell:
        "samtools sort -@ {threads} -o {output.bam_sorted} {input.bam}"

rule mark_duplicates:
    input:
        bam_sorted = "tmp/results/{sample}_sorted.bam"
    output:
        bam_markdup = "tmp/results/{sample}_markdup.bam",
        bai_markdup = "tmp/results/{sample}_markdup.bai",
        dup_metrics = "tmp/metrics/markdup/{sample}_markdup_metrics.txt"
    shell:
        """
        java -jar {picard} MarkDuplicates \
        I={input.bam_sorted} \
        O={output.bam_markdup} \
        M={output.dup_metrics} \
        CREATE_INDEX=true

        """

# Generates alignment metrics
# Picard tools require path to picard.jar
picard = "/home/joshj/tools/picard/picard.jar"
rule alignment_metrics:
    input:
        bam = "tmp/results/{sample}_markdup.bam"
    output:
        stats = "tmp/metrics/alignment/{sample}_samtools_stats.txt",
        insert_metrics = "tmp/metrics/alignment/{sample}_insert_size_metrics.txt",
        insert_hist = "tmp/metrics/alignment/{sample}_insert_size_histogram.pdf"
    shell:
        """
        # Generate alignment stats
        samtools stats {input.bam} > {output.stats}

        # Collect insert size metrics
        # M = 0.5 means 50% of reads must fall within the insert size peak to generate metrics
        java -jar {picard} CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} \
            M=0.5
            
        """ 