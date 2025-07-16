"""
--- ex_alignment.smk ---

Rules for aligning umapped, non-deduplicated reads to reference genome, for experimental samples

Input: Processed (demuxed, trimmed and length filtered) FASTQ files
Output: Reads aligned to a reference genome (BAM) 

Authors: 
    - James Phie
    - Cameron Fraser

"""

"""
Map reads to reference genome
"""
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
        bam = temp("tmp/{ex_sample}/{ex_sample}_map.bam"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_tmp.sam")
    log:
        "logs/{ex_sample}/ex_map.log"
    benchmark:
        "logs/{ex_sample}/ex_map.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem -t {threads} -Y {input.ref} {input.fastq1} {input.fastq2} > {output.intermediate_sam} 2>> {log}

        samtools view -@ {threads} -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """


"""
Filter mapped reads
    - Remove read pairs that are on different chromosomes
    - Remove reads pairs that are too far apart (~500bp, determined by aligner)
    - Remove read pairs that are not read in the correct directions
"""
rule ex_filter_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_correct.bam")
    log:
        "logs/{ex_sample}/ex_filter_correct_product.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_correct_product.benchmark.txt"
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        samtools view -b -f 0x2 {input.bam} > {output.bam} 2>> {log}
        """