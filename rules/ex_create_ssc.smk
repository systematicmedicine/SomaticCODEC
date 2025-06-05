"""
--- ex_create_ssc.smk ---

Rules for creating a single strand consensus from aligned BAM

Input: Reads aligned to reference genome (BAM), for experimental samples
Output: Same as input, but PCR duplicates collapsed based on UMI to create a molecular consensus of read 1s and read 2s

Author: James Phie

"""
# Load sample metadata
sample_names = list(pd.read_csv(config["ex_samples"])["samplename"])

rule ex_umitag:
    input:
        bam = "tmp/{sample}/{sample}_map.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi1.bam")
    threads:
        config['ncores']
    resources:
        mem = 32
    shell:
        """
        #Move UMI from readname to RX:Z: tag and sort by name for UMI consensus steps
        fgbio \
            -Xmx{resources.mem}g \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o /dev/stdout \
            --remove-umi true | \
        samtools sort -n -@ {threads} -o {output.bam}
        """
# Adds mate information to PE reads (e.g. read 1's information to read 2, read 2's information to read 1). Tags include MC:Z:, MQ:i, RNEXT, PNEXT, TLEN, FLAGs. These tags are required for groupbyUMI, SSC and DSC. 
rule ex_addmate:
    input:
        bam = "tmp/{sample}/{sample}_map_umi1.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi2.bam")
    shell:
        """
        fgbio SetMateInformation \
        -i {input.bam} \
        -o {output.bam}
        """

# Uses UMI tags (RX:Z:<UMI>) to assign identical MI tags to any reads within 1 edit distance of each other, for later SSC and DSC collapse.  
rule ex_groupbyumi:
    input:
        bam = "tmp/{sample}/{sample}_map_umi2.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi3.bam"),
        histogram = "metrics/{sample}/{sample}_map_umi3_metrics.txt"
    threads:
        config['ncores']
    resources:
        mem = 32
    shell:
        """
        fgbio \
            -Xmx{resources.mem}g \
            --compression 1 --async-io \
            GroupReadsByUmi \
            --min-umi-length 6 \
            -i {input.bam} \
            -o {output.bam} \
            -f {output.histogram} \
            -@ {threads} \
            -m 0 \
            --strategy=adjacency
        """
# Collects a consensus of all read 1's of the same MI, and all read 2's of the same MI, to make use of PCR/optical duplicates and create a more accurate single strand consensus. Due to the changes in sequences, this bam is now unmapped and will require realignment. 
rule ex_ssc:
    input:
        bam = "tmp/{sample}/{sample}_map_umi3.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_unmap_ssc.bam")
    resources:
        mem = 32
    shell:
        """
        fgbio \
            -Xmx{resources.mem}g \
            --compression 1 CallMolecularConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            --consensus-call-overlapping-bases false \
            -M 1
        """
# Adds read group information to the ssc bam. This information is not particularly useful, but required by downstream fgbio tools. 
rule ex_addrg:
    input:
        bam = "tmp/{sample}/{sample}_unmap_ssc.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_unmap_ssc_rg.bam")
    params:
        sample = lambda wildcards: wildcards.sample
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam} \
            RGID={params.sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={params.sample} \
            VALIDATION_STRINGENCY=LENIENT
        """
# Converts unmapped ssc bam to fastq in preparation for realignment
rule ex_bam_to_fastq:
    input:
        bam = "tmp/{sample}/{sample}_unmap_ssc_rg.bam"
    output:
        fastq = temp("tmp/{sample}/{sample}_ssc.fastq")
    threads:
        1
    shell:
        """
        samtools fastq {input.bam} > {output.fastq}
        """

# Realigns the unmapped ssc bam. Uses BWA-mem2 with the same arguments as the original alignment, with the addition of -p to indicate the input bam is interleaved PE reads. 
rule ex_map_ssc:
    input:
        fastq = "tmp/{sample}/{sample}_ssc.fastq",
    output:
        sam = temp("tmp/{sample}/{sample}_map_ssc.sam")
    threads: 
        config['ncores']
    params:
        reference = config['ref'],
    shell:
        """
        bwa-mem2 mem \
        -t {threads} \
        -p \
        -Y \
        {params.reference} {input.fastq} \
        > {output.sam}
        """

# Creates an aligned bam from the aligned sam file output from bwa-mem2.
rule ex_sscsamtobam:
    input:
        sam = "tmp/{sample}/{sample}_map_ssc.sam",
    output:
        bam = temp("tmp/{sample}/{sample}_map_ssc.bam")
    threads: 
        config['ncores']
    shell:
        """
        samtools view -@ {threads} -bS -o {output.bam} {input.sam}
        """

# Adds metadata (e.g. MI, rg tags from addrg) to the mapped bam from the unmapped bam. This is required because alignment tools remove all metadata from the bam. 
rule ex_zipdata: 
    input:
        mapped = "tmp/{sample}/{sample}_map_ssc.bam",
        unmapped = "tmp/{sample}/{sample}_unmap_ssc_rg.bam",
    output:
        bam = temp("tmp/{sample}/{sample}_map_ssc_anno.bam"),
        bai = temp("tmp/{sample}/{sample}_map_ssc_anno.bam.bai")
    params:
        reference = config['ref'],
    resources:
        mem = 4,
    threads:
        config['ncores']
    shell:
        """
        fgbio -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            --compression 0 --async-io ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {params.reference} \
            --tags-to-revcomp Consensus \
        | samtools sort - -o {output.bam} -O BAM -@ {threads} \
        && samtools index {output.bam} -@ {threads}
        """
# Calculates 'insert size' (distance between start of watson and end of crick)
rule ex_sscinsert_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map_ssc_anno.bam",
    output:
        txt = "metrics/{sample}/{sample}_map_ssc_insert_metrics.txt",
        hist = "metrics/{sample}/{sample}_map_ssc_insert_metrics.pdf",
    resources:
        mem = 32
    shell:
        """
        picard \
            -Xmx{resources.mem}g \
            -Djava.io.tmpdir=tmp \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100
        """

# Standard WGS metrics including depth and genome territory covered, applied to the ssc bam. 
rule ex_sscdepth_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map_ssc_anno.bam",
    output:
        metrics = "metrics/{sample}/{sample}_ssc_depth_metrics.txt",
    params:
        ref = config['ref'],
    resources:
        mem = 30,
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectWgsMetrics \
            I={input.bam} \
            O={output.metrics} \
            R={params.ref} \
            INCLUDE_BQ_HISTOGRAM=true \
            MINIMUM_BASE_QUALITY=30
        """
# Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
rule ex_duplication_metrics:
    input:
        expand("metrics/{sample}/{sample}_map_umi3_metrics.txt", sample=sample_names)
    output:
        "metrics/duplication_metrics.txt"
    script:
        "../scripts/duplication.py"
