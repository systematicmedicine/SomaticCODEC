"""
--- ex_create_dsc.smk ---

Rules for creating a collapsed (deduplicated) double stranded (duplex) consensus for experimental samples

Input: Reads aligned to reference genome (BAM), for experimental samples
Output: Double stranded consensus

1. Reads are marked as duplicates using molecular UMIs, which were originally extracted into the readnames from raw reads during trimming. 
2. Duplicate reads are then collapsed into consensus sequences for read 1 and read 2
3. Read 1 and read 2 are collapsed to create a double stranded consensus, which includes single strand overhangs and read 1 read 2 disagreements marked as N

Author: James Phie

"""
# Annotate the aligned bam with correct product to be umi aware for duplex sequencing
    # Move umi from readname to RX:Z: tag
    # Add mate information to read pairs 
    # Assign molecular identifiers based on RX:Z: umi tags to allow for single and duplex strand consensus generation
    # Assign general sample and read group related metadata for downstream tools
rule ex_annotate_umi:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi.bam"),
        histogram = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"
    threads:
        max(1, os.cpu_count() // 16)
    resources:
        mem = 32
    params:
        ex_sample = lambda wc: wc.ex_sample
    shell:
        """
        set -euo pipefail

        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o /dev/stdout \
            --remove-umi true | \

        samtools sort -n -@ {threads} -o /dev/stdout | \

        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            SetMateInformation \
            -i /dev/stdin \
            -o /dev/stdout | \

        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 1 --async-io \
            GroupReadsByUmi \
            --min-umi-length 6 \
            -i /dev/stdin \
            -o /dev/stdout \
            -f {output.histogram} \
            -@ {threads} \
            -m 0 \
            --strategy=adjacency | \

        picard AddOrReplaceReadGroups \
            I=/dev/stdin \
            O={output.bam} \
            RGID={params.ex_sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={params.ex_sample} \
            VALIDATION_STRINGENCY=LENIENT
        """

# Sort umi aware bam by coordinates for duplex consensus calling
rule ex_sort_by_template:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi_sorted.bam")
    resources:
        mem = 16
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            SortBam \
            -i {input.bam} \
            -o {output.bam} \
            -s TemplateCoordinate
        """

# Create duplex consensus bam using molecular identifiers
    # All read 1's, and all read 2's belonging to a single molecular identifier are collapsed for single strand consensus (PCR duplicates)
    # All read 1 consensus and read 2 consensus belonging to a single molecular identifier are collapsed for duplex strand consensus 
    # Single stranded overhangs are retained for alignment purposes, but a Q of 2 is assigned to all single strand bases
    # Reads with >4 disagreements between overlapping paired end reads are excluded
rule ex_call_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi_sorted.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam")
    resources:
        mem = 32
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
         CallCodecConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            -M 1
        """

# Align the dsc to the reference genome as sequences have changed
    # Single stranded overhangs are present in this bam to assist with alignment (filtered out during variant calling with base quality filter)
    # Aligned bam is sorted by readname for downstream annotation
rule ex_remap_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam",
        ref = config["GRCh38_path"],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config["GRCh38_path"] + ".0123"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.bam")
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        samtools fastq {input.bam} | \
        bwa-mem2 mem -t {threads} -Y {input.ref} - | \
        samtools sort -n -@ {threads} -o {output.bam}
        """

# Add metadata from unmapped dsc bam back to the mapped dsc bam
rule ex_annotate_dsc: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    output:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai"
    resources:
        mem = 32
    threads:
        max(1, os.cpu_count() // 16)
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {input.ref} \
            --tags-to-revcomp Consensus \
        | samtools sort - -o {output.bam} -O BAM -@ {threads} \
        && samtools index {output.bam} -@ {threads}
        """

# Filter the dsc bam to prepare for variant calling 
    # Remove reads with mapQ <= 60
rule ex_filter_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai")
    shell:
        """
        samtools view -b -q 60 {input.bam} > {output.bam}
        samtools index {output.bam}
        """