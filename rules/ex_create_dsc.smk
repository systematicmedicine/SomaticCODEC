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

#Move UMI from readname to RX:Z: tag and sort by name for UMI consensus steps
rule ex_umitag:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi1.bam")
    threads:
        max(1, os.cpu_count() // 16)
    resources:
        mem = 32
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o /dev/stdout \
            --remove-umi true | \
        samtools sort -n -@ {threads} -o {output.bam}
        """
# Adds mate information to PE reads (e.g. read 1's information to read 2, read 2's information to read 1). Tags include MC:Z:, MQ:i, RNEXT, PNEXT, TLEN, FLAGs. These tags are required for groupbyUMI, SSC and DSC. 
rule ex_addmate:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi1.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi2.bam")
    resources:
        mem = 32
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
        SetMateInformation \
        -i {input.bam} \
        -o {output.bam}
        """

# Uses UMI tags (RX:Z:<UMI>) to assign identical MI tags to any reads within 1 edit distance of each other, for later SSC and DSC collapse.  
rule ex_groupbyumi:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi2.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi3.bam"),
        histogram = "metrics/{ex_sample}/{ex_sample}_map_umi3_metrics.txt"
    threads:
        max(1, os.cpu_count() // 16)
    resources:
        mem = 32
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 1 --async-io \
            GroupReadsByUmi \
            --min-umi-length 6 \
            -i {input.bam} \
            -o {output.bam} \
            -f {output.histogram} \
            -@ {threads}
            -m 0 \
            --strategy=adjacency
        """

# Sort MI marked bam (before duplicate collapse) by coordinates for callcodecconsensusreads
rule ex_sort_for_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi3.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi3_sorted.bam")
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

# Call codec consensus reads using MI marked bam (before duplicate collapse)
rule ex_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi3_sorted.bam"
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

# Add read group information to the dsc bam file (not particularly useful information, but required by downstream tools)
rule ex_addrg:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc_rg.bam")
    params:
        ex_sample = lambda wildcards: wildcards.ex_sample
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam} \
            RGID={params.ex_sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={params.ex_sample} \
            VALIDATION_STRINGENCY=LENIENT
        """

# Convert the unmapped dsc bam to an unmapped fastq file for realignment 
rule ex_dsc_bam_to_fastq:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_unmap_dsc_rg.bam"
    output:
        fastq = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc_rg.fastq")
    shell:
        """
        samtools fastq {input.bam} > {output.fastq}
        """

# Align the dsc (with ss overhangs) to the reference genome as sequences have changed
rule ex_map_dsc:
    input:
        fq = "tmp/{ex_sample}/{ex_sample}_unmap_dsc_rg.fastq",
        ref = config["GRCh38_path"],
        amb = config["GRCh38_path"] + ".amb",
        ann = config["GRCh38_path"] + ".ann",
        bwt = config["GRCh38_path"] + ".bwt.2bit.64",
        pac = config["GRCh38_path"] + ".pac",
        sa = config["GRCh38_path"] + ".sa"
    output:
        sam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.sam")
    threads: 
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 mem -t {threads} -Y {input.ref} {input.fq} > {output.sam}
        """

# Convert dsc sam to dsc bam and sort by readname (querynamesort)
rule ex_samtobam_dsc:
    input:
        sam = "tmp/{ex_sample}/{ex_sample}_map_dsc.sam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.bam")
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        samtools sort -n -@ {threads} -o {output.bam} {input.sam}
        """

# Add metadata from unmapped dsc bam back to the mapped dsc bam
rule ex_zipdata: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_dsc_rg.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai")
    resources:
        mem = 4,
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

# Add a rule to filter dsc for only duplex bases (ie. remove single strand overhangs and R1R2 disagreements) - functionality not yet built into CallCodecConsensusReads

# Depth and genome territory covered, applied to the dsc bam. Currently without filtering, so this includes single strand overhangs (ie. not true duplex depth)
rule ex_dscdepth_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_depth_metrics.txt",
    resources:
        mem = 30,
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectWgsMetrics \
            I={input.bam} \
            O={output.metrics} \
            R={input.ref} \
            INCLUDE_BQ_HISTOGRAM=true \
            MINIMUM_BASE_QUALITY=30
        """
