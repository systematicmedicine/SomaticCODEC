"""
--- ex_create_dsc.smk ---

Rules for creating a double stranded (duplex) consensus for experimental samples

Input: Single stranded consensus
Output: Double stranded consensus

Author: James Phie

Temporary dev notes:
- The below is a placeholder from a single sample from codec dev (working code)
- This will be converted once fulcrum publishes CallCodecConsensusReads (potentially sooner if required)
- Once ex_create_dsc.smk is added to the pipeline, some steps in ex_create_ssc may be redundant, and we should consider removing them (or moving to optional snakefile)
to speed up the pipeline

"""
import pandas as pd
from Bio import SeqIO

# Load config
workdir: config["cwd"]
REF = config['ref']
EVAL_REGION_BED = config['region_bed']
EVAL_REGION_IL = config['region_interval_list']
DBSNP = config['dbsnp']
tmpdir = config['tmpdir']
inputdata_file = config["input_meta"]
r1start = config["r1start"]
r2start = config["r2start"]
r1end = config["r1end"]
r2end = config["r2end"]
ncores = config["ncores"]

rule all:
    input:
        "../raw/ex_hek1.1_unmap_dsc.bam",
        "exp_map_dsc/ex_hek1.1_map_dsc.bam",
        "exp_addrg/ex_hek1.1_unmap_dsc_rg.bam",
        "exp_annotate_dsc/ex_hek1.1_map_dsc_anno.bam",
        "exp_annotate_dsc/ex_hek1.1_map_dsc_anno.bam.bai"

# Sort MI marked bam (before duplicate collapse) by coordinates for callcodecconsensusreads
rule exp_sort_for_dsc:
    input:
        "../raw/ex_hek1.1_map_umi3_chr1.bam"
    output:
        "../raw/ex_hek1.1_map_umi3_chr1_sorted.bam"
    shell:
        """
        fgbio SortBam \
            -i {input} \
            -o {output} \
            -s TemplateCoordinate
        """

# Call codec consensus reads using MI marked bam (before duplicate collapse)
rule exp_dsc:
    input:
        bam = "../raw/ex_hek1.1_map_umi3_chr1_sorted.bam"
    output:
        bam = "../raw/ex_hek1.1_unmap_dsc.bam"
    resources:
        mem = 32
    shell:
        """
        fgbio CallCodecConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            -M 1
        """

# Add read group information to the dsc bam file (not particularly useful information, but required by downstream tools)
rule exp_addrg:
    input:
        bam = "../raw/ex_hek1.1_unmap_dsc.bam"
    output:
        bam = "exp_addrg/ex_hek1.1_unmap_dsc_rg.bam"
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam} \
            RGID=ex_hek1.1 \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM=ex_hek1.1 \
            VALIDATION_STRINGENCY=LENIENT
        """

# Convert the unmapped dsc bam to an unmapped fastq file for realignment 
rule exp_dsc_bam_to_fastq:
    input:
        bam = "exp_addrg/ex_hek1.1_unmap_dsc_rg.bam"
    output:
        fq = temp("tmp/ex_hek1.1.fastq")
    shell:
        """
        samtools fastq {input.bam} > {output.fq}
        """

# Align the dsc (with ss overhangs) to the reference genome as sequences have changed
rule exp_map_dsc:
    input:
        fq = "tmp/ex_hek1.1.fastq"
    output:
        sam = temp("tmp/ex_hek1.1.sam")
    threads: ncores
    params:
        reference = REF
    shell:
        """
        bwa-mem2 mem -t {threads} -Y {params.reference} {input.fq} > {output.sam}
        """

# Convert dsc sam to dsc bam and sort by readname (querynamesort)
rule exp_sam_to_bam_dsc:
    input:
        sam = "tmp/ex_hek1.1.sam"
    output:
        bam = "exp_map_dsc/ex_hek1.1_map_dsc.bam"
    threads: ncores
    shell:
        """
        samtools sort -n -@ {threads} -o {output.bam} {input.sam}
        """

# Add metadata from unmapped dsc bam back to the mapped dsc bam
rule exp_zipdata: 
    input:
        mapped = "exp_map_dsc/ex_hek1.1_map_dsc.bam",
        unmapped = "exp_addrg/ex_hek1.1_unmap_dsc_rg.bam",
    output:
        bam = "exp_annotate_dsc/ex_hek1.1_map_dsc_anno.bam",
        bai = "exp_annotate_dsc/ex_hek1.1_map_dsc_anno.bam.bai"
    params:
        reference = REF,
    resources:
        mem = 4,
    threads:
        ncores
    shell:
        """
        fgbio ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {params.reference} \
            --tags-to-revcomp Consensus \
        | samtools sort - -o {output.bam} -O BAM -@ {threads} \
        && samtools index {output.bam} -@ {threads}
        """

# Add metrics files (e.g. duplex depth (considering ss overhangs), etc.)