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
        fastq1 = "tmp/{sample}/{sample}_r1_trimfilter.fastq.gz",
        fastq2 = "tmp/{sample}/{sample}_r2_trimfilter.fastq.gz"
    output:
        sam = temp("tmp/{sample}/{sample}_map.sam")
    threads: 
        config['ncores']
    params:
        reference = config["ref"],
    shell:
        """
        bwa-mem2 mem \
            -t {threads} \
            -Y \
            {params.reference} {input.fastq1} {input.fastq2} \
            > {output.sam}
        """

# Creates an aligned bam from the aligned sam file output from bwa-mem2.
rule ex_samtobam:
    input:
        sam = "tmp/{sample}/{sample}_map.sam",
    output:
        bam = temp("tmp/{sample}/{sample}_map.bam")
    threads: 
        config['ncores']
    shell:
        """
        samtools view -@ {threads} -bS -o {output.bam} {input.sam}
        """

# Collects alignment metrics from the aligned bam using samtools flagstat
rule ex_map_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map.bam"
    output:
        txt = "metrics/{sample}/{sample}_map_metrics.txt"
    shell:
        """
        #Alternatively, picard's CollectAlignmentSummaryMetrics has more detailed metrics but will take much longer (?1 hour per sample vs ?2 minutes per sample)
        #Samtools flagstat has required metrics for this stage
        samtools flagstat {input.bam} > {output.txt}
        """

# Replace default index names with experiment specific sample names as defined in the input.tsv
rule ex_correctproduct_metrics:
    input:
        demux_json = "metrics/demux_metrics.json",
        trim_reports = expand("metrics/{sample}/{sample}_trimfilter_metrics.json", sample=ex_sample_names),
        flagstats = expand("metrics/{sample}/{sample}_map_metrics.txt", sample=ex_sample_names)
    output:
        "metrics/correctproduct_metrics.txt"
    params:
        samples = ex_sample_names
    script:
        "../scripts/correctproduct.py"
