"""
--- ex_alignment.smk ---

Rules for aligning reads to reference genome, for experimental samples

Input: Processed FASTQ files
Output: Reads aligned to a reference genome (BAM) 

Author: James Phie

"""

# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])

# Creates an aligned bam from trimmed and filtered fastq files. Softclipping allowed.
rule ex_align:
    input:
        fastq1 = "tmp/{sample}/{sample}_r1_trimfilter.fastq.gz",
        fastq2 = "tmp/{sample}/{sample}_r2_trimfilter.fastq.gz"
    output:
        bam = temp("tmp/{sample}/{sample}_map.bam")
    threads: 
        ncores
    params:
        reference = config["ref"],
    shell:
        """
        #0x2 flag calculated based on ... first 256k high-confidence read pairs, >~500bp gap between R1R2 not properly paired
        bwa-mem2 mem \
            -t {threads} \
            -Y \
            {params.reference} {input.fastq1} {input.fastq2} | \
        samtools view -o {output.bam}
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
        trim_reports = expand("metrics/{sample}/{sample}_trimfilter_metrics.json", sample=sample_names),
        flagstats = expand("metrics/{sample}/{sample}_map_metrics.txt", sample=sample_names)
    output:
        "metrics/correctproduct_metrics.txt"
    params:
        samples = sample_names
    script:
        "scripts/correctproduct.py"
