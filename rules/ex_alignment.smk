"""
--- ex_alignment.smk ---

Rules for aligning umapped, non-deduplicated reads to reference genome, for experimental samples

Input: Processed (trimmed and length filtered) FASTQ files
Output: Reads aligned to a reference genome (BAM) 

Author: James Phie

"""
# Creates an aligned sam from trimmed and filtered fastq files. Softclipping allowed.
rule ex_map:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz",
        ref = config["GRCh38_path"],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config["GRCh38_path"] + ".sa"
    output:
        sam = temp("tmp/{ex_sample}/{ex_sample}_map.sam")
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem \
            -t {threads} \
            -Y \
            {input.ref} {input.fastq1} {input.fastq2} \
            > {output.sam}
        """

# Creates an aligned bam from the aligned sam file output from bwa-mem2.
rule ex_samtobam:
    input:
        sam = "tmp/{ex_sample}/{ex_sample}_map.sam",
    output:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam" #Make temp again once pipeline development is complete
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        samtools view -@ {threads} -bS -o {output.bam} {input.sam}
        """

# Collects alignment metrics from the aligned bam using samtools flagstat
rule ex_map_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
    shell:
        """
        #Alternatively, picard's CollectAlignmentSummaryMetrics has more detailed metrics but will take much longer (?1 hour per sample vs ?2 minutes per sample)
        #Samtools flagstat has required metrics for this stage
        samtools flagstat {input.bam} > {output.txt}
        """


