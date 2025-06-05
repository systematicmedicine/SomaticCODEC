"""
--- ms_alignment.smk ---

Rules for performing a raw alignment with matched sample trimmed and filtered reads

Input: Processed ms FASTQ files
Outputs: 
    - ms raw alignment BAM
    - Metrics files

Author: Joshua Johnstone

"""
# Indexes reference for use in alignment
rule index_ref:
    input:
        ref = ref
    output:
        bwt = ref + ".bwt"
    shell:
        "bwa index {input.ref}"

# Aligns reads to Chr21 reference
rule raw_alignment:
    input: 
        ref = ref,
        r1_processed = "tmp/data/processed/{sample}_r1.fastq",
        r2_processed = "tmp/data/processed/{sample}_r2.fastq"
    output:
        bam = "tmp/results/{sample}_aligned.bam"
    threads: 8
    shell:
        """
        bwa mem -R "@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tPL:ILLUMINA" \
            -t {threads} \
            {input.ref} \
            {input.r1_processed} \
            {input.r1_processed} | \
        samtools view -bS - > {output.bam}

        """

# Sorts bam by coordinate
rule sort_bam:
    input:
        bam = "tmp/results/{sample}_aligned.bam"
    output:
        bam_sorted =  "tmp/results/{sample}_sorted.bam"
    shell:
        "samtools sort -o {output.bam_sorted} {input.bam}"

# Generates alignment metrics

rule alignment_metrics:
    input:
        bam = "tmp/results/{sample}_sorted.bam"
    output:
        stats = "tmp/metrics/{sample}_samtools_stats.txt",
        insert_metrics = "tmp/metrics/{sample}_insert_size_metrics.txt",
        insert_hist = "tmp/metrics/{sample}_insert_size_histogram.pdf"
    shell:
        """
        # Generate alignment stats
        samtools stats {input.bam} > {output.stats}

        # Collect insert size metrics
        # M = 0.5 means 50% of reads must fall within the insert size peak to generate metrics
        picard CollectInsertSizeMetrics \
            I = {input.bam} \
            O = {output.insert_metrics} \
            H = {output.insert_hist} \
            M = 0.5
            
        """ 


# rule mark_duplicates:
#     input:
#         bam_sorted = "tmp/results/{sample}_sorted.bam"
#     output:
#         bam_markdup = "tmp/results/{sample}_markdup.bam",
#         metrics = "tmp/results/{sample}_markdup_metrics.txt"
#     shell:
#         "picard MarkDuplicates "
#         "I={input.bam_sorted} "
#         "O={output.bam_markdup} "
#         "M={output.metrics} "
#         "CREATE_INDEX=true "
#         "VALIDATION_STRINGENCY=SILENT"

# rule index_bam:
#     input:
#         bam_markdup = "results/{sample}_markdup.bam"
#     output:
#         bai_markdup = "results/{sample}_markdup.bam.bai"
#     shell:
#         "samtools index {input.bam_markdup}"