"""
--- ex_alignment.smk ---

Rules for aligning umapped, non-deduplicated reads to reference genome, for experimental samples

Input: Processed (trimmed and length filtered) FASTQ files
Output: Reads aligned to a reference genome (BAM) 

Author: James Phie

"""
# Creates an aligned bam from trimmed and filtered fastq files. Softclipping allowed.
rule ex_map:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz",
        ref = config["GRCh38_path"],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config["GRCh38_path"] + ".0123"
    output:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem -t {threads} -Y {input.ref} {input.fastq1} {input.fastq2} | \
        samtools view -@ {threads} -bS -o {output.bam} -
        """

# Filters reads that are not correctly paired (ie. on the same chromosome within ~500bp, in the correct directions - likely codecseq intermolecular byproducts)
rule ex_filter_correct:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_correct.bam")
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        samtools view -b -f 0x2 {input.bam} > {output.bam}
        """

# Collects alignment metrics from the aligned bam using samtools flagstat
rule ex_map_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.txt}
        """