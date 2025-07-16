"""
--- ex_create_dsc.smk ---

Rules for creating a collapsed (deduplicated) double stranded (duplex) consensus for experimental samples

Input: Reads aligned to reference genome (BAM), for experimental samples
Output: Double stranded consensus

1. Reads are marked as duplicates using molecular UMIs, which were originally extracted into the readnames from raw reads during trimming. 
2. Duplicate reads are then collapsed into consensus sequences for read 1 and read 2
3. Read 1 and read 2 are collapsed to create a double stranded consensus, which includes single strand overhangs and read 1 read 2 disagreements marked as N

Authors: 
    - James Phie
    - Cameron Fraser
"""


"""
 Annotate the mapped reads for downstream rules
    - Move UMI from read name to RX:Z tag
    - Add mate information to read pairs
    - Assign molecular identifiers based on RX:Z: umi tags to allow for single and duplex strand consensus generation
    - Assign generic sample and read group metadata for tool compatibility
"""
rule ex_annotate_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_anno.bam"),
        histogram = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt",
        intermediate_moveumi = temp("tmp/{ex_sample}/{ex_sample}_map__moveumi_tmp.bam"),
        intermediate_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_sorted_tmp.bam"),
        intermediate_mateinfo = temp("tmp/{ex_sample}/{ex_sample}_map_mateinfo_tmp.bam"),
        intermediate_groupbyumi = temp("tmp/{ex_sample}/{ex_sample}_map_groupbyumi_tmp.bam")
    log:
        "logs/{ex_sample}/annotate_bam.log"
    benchmark:
        "logs/{ex_sample}/annotate_bam.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 16)
    resources:
        mem = 64
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o {output.intermediate_moveumi} \
            --remove-umi true 2>> {log}

        samtools sort -n -@ {threads} -o {output.intermediate_sorted} {output.intermediate_moveumi} 2>> {log}

        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            SetMateInformation \
            -i {output.intermediate_sorted} \
            -o {output.intermediate_mateinfo} 2>> {log}

        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 1 --async-io \
            GroupReadsByUmi \
            --min-umi-length 6 \
            -i {output.intermediate_mateinfo} \
            -o {output.intermediate_groupbyumi} \
            -f {output.histogram} \
            -@ {threads} \
            -m 0 \
            --strategy=adjacency 2>> {log}

        picard AddOrReplaceReadGroups \
            I={output.intermediate_groupbyumi} \
            O={output.bam} \
            RGID={wildcards.ex_sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={wildcards.ex_sample} \
            VALIDATION_STRINGENCY=LENIENT 2>> {log}
        """


"""
Sort the mapped reads by coordinates
    - Required for duplex consensus calling
"""
rule ex_sort_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_template_sorted.bam")
    log:
        "logs/{ex_sample}/ex_sort_by_template.log"
    benchmark:
        "logs/{ex_sample}/ex_sort_by_template.benchmark.txt"
    resources:
        mem = 64
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
            SortBam \
            -i {input.bam} \
            -o {output.bam} \
            -s TemplateCoordinate 2>> {log}
        """


"""
Create duplex consensus (DSC)
    - All read 1's, and all read 2's belonging to a single molecular identifier are collapsed for single strand consensus (PCR duplicates)
    - All read 1 consensus and read 2 consensus belonging to a single molecular identifier are collapsed for duplex strand consensus 
    - Single stranded overhangs are retained for alignment purposes, but a Q of 2 is assigned to all single strand bases
    - Reads with >3 disagreements between overlapping paired end reads are excluded
"""
rule ex_call_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_template_sorted.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam")
    log:
        "logs/{ex_sample}/ex_call_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_call_dsc.benchmark.txt"
    resources:
        mem = 64
    shell:
        """
        JAVA_OPTS="-Xmx{resources.mem}g -Djava.io.tmpdir=tmp" fgbio \
         CallCodecConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            --max-duplex-disagreements 3 \
            --single-strand-qual 2 \
            -M 1 2>> {log}
        """


"""
Realign the DSC to the reference genome
    - This is required because the conensus sequence may differe from the sequences previously used for alignment
    - Single stranded overhangs are present in this BAM to assist with alignment (ideally filtered later)
"""
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
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam"),
        intermediate_fastq = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc_tmp.fastq"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted_tmp.sam")
    log:
        "logs/{ex_sample}/ex_remap_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_remap_dsc.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        samtools fastq -0 {output.intermediate_fastq} {input.bam} 2>> {log}

        bwa-mem2 mem -t {threads} -Y {input.ref} {output.intermediate_fastq} > {output.intermediate_sam} 2>> {log}

        samtools view -@ {threads} -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """


"""
Sort realigned DSC by read name
    - Required for downstream rules
"""
rule ex_sort_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.bam")
    log:
        "logs/{ex_sample}/ex_sort_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_sort_dsc.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        samtools sort -n -@ {threads} -o {output.bam} {input.bam} 2>> {log}
        """


"""
Add metadata to the DSC
    - Replace metadata lost during alignment
"""
rule ex_annotate_dsc: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai"),
        intermediate_anno = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_tmp.bam")
    log:
        "logs/{ex_sample}/ex_annotate_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_annotate_dsc.benchmark.txt"
    resources:
        mem = 64
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
            -o {output.intermediate_anno} 2>> {log}

        samtools sort -@ {threads} -o {output.bam} {output.intermediate_anno} 2>> {log}

        samtools index -@ {threads} {output.bam} 2>> {log}
        """


"""
Filter reads from DSC
    - Remove reads with mapQ <= 60
"""
rule ex_filter_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"
    output:
        intermediate_bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered_unsorted.bam"),
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai")
    log:
        "logs/{ex_sample}/ex_filter_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"
    shell:
        """
        samtools view -b -q 60 {input.bam} > {output.intermediate_bam} 2>> {log}
        samtools sort -o {output.bam} {output.intermediate_bam} 2>> {log}
        samtools index {output.bam} 2>> {log}
        """