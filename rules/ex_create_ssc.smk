"""
--- ex_create_ssc.smk ---

Rules for creating a single strand consensus from aligned BAM

Input: Reads aligned to reference genome (BAM), for experimental samples
Output: Same as input, but PCR duplicates collapsed based on UMI to create a molecular consensus of read 1s and read 2s

Author: James Phie

"""

# Collects a consensus of all read 1's of the same MI, and all read 2's of the same MI, to make use of PCR/optical duplicates and create a more accurate single strand consensus. Due to the changes in sequences, this bam is now unmapped and will require realignment. 
rule ex_ssc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_umi3.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_ssc.bam")
    resources:
        mem = 32
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 1 CallMolecularConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            --consensus-call-overlapping-bases false \
            -M 1
        """
# Adds read group information to the ssc bam. This information is not particularly useful, but required by downstream fgbio tools. 
rule ex_addrg:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_unmap_ssc.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_ssc_rg.bam")
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
# Converts unmapped ssc bam to fastq in preparation for realignment
rule ex_bam_to_fastq:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_unmap_ssc_rg.bam"
    output:
        fastq = temp("tmp/{ex_sample}/{ex_sample}_ssc.fastq")
    threads:
        1
    shell:
        """
        samtools fastq {input.bam} > {output.fastq}
        """

# Realigns the unmapped ssc bam. Uses BWA-mem2 with the same arguments as the original alignment, with the addition of -p to indicate the input bam is interleaved PE reads. 
rule ex_map_ssc:
    input:
        fastq = "tmp/{ex_sample}/{ex_sample}_ssc.fastq",
    output:
        sam = temp("tmp/{ex_sample}/{ex_sample}_map_ssc.sam")
    threads: 
        config['ncores']
    params:
        pers_ref = lambda wc: f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_personalized_ref.fasta" #Rename based on ms pipeline
    shell:
        """
        bwa-mem2 mem \
        -t {threads} \
        -p \
        -Y \
        {params.pers_ref} {input.fastq} \
        > {output.sam}
        """

# Creates an aligned bam from the aligned sam file output from bwa-mem2.
rule ex_sscsamtobam:
    input:
        sam = "tmp/{ex_sample}/{ex_sample}_map_ssc.sam",
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_ssc.bam")
    threads: 
        config['ncores']
    shell:
        """
        samtools view -@ {threads} -bS -o {output.bam} {input.sam}
        """

# Adds metadata (e.g. MI, rg tags from addrg) to the mapped bam from the unmapped bam. This is required because alignment tools remove all metadata from the bam. 
rule ex_zipdata: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_ssc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_ssc_rg.bam",
        pers_ref = lambda wc: f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_personalized_ref.fasta" #Rename based on ms pipeline
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_ssc_anno.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_ssc_anno.bam.bai")
    resources:
        mem = 4,
    threads:
        config['ncores']
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 0 --async-io ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {input.pers_ref} \
            --tags-to-revcomp Consensus \
        | samtools sort - -o {output.bam} -O BAM -@ {threads} \
        && samtools index {output.bam} -@ {threads}
        """


