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
Create duplex consensus (DSC)
    - All read 1's, and all read 2's belonging to a single molecular identifier are collapsed for single strand consensus (PCR duplicates)
    - All read 1 consensus and read 2 consensus belonging to a single molecular identifier are collapsed for duplex strand consensus 
    - Single stranded overhangs are retained for alignment purposes, but a Q of 2 is assigned to all single strand bases
    - Reads with >3 disagreements between overlapping paired end reads are excluded
"""
rule ex_call_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam"),
        metrics = "metrics/{ex_sample}/{ex_sample}_call_codec_consensus_metrics.txt"
    params:
        max_duplex_disagreements = config["ex_call_dsc"]["max_duplex_disagreements"],
        min_read_pairs = config["ex_call_dsc"]["min_read_pairs"],
        single_strand_qual = config["ex_call_dsc"]["single_strand_qual"]
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
            --max-duplex-disagreements {params.max_duplex_disagreements} \
            --single-strand-qual {params.single_strand_qual} \
            --min-read-pairs {params.min_read_pairs} \
            --stats {output.metrics} 2>> {log}
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
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.bam"),
        intermediate_fastq = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc_tmp.fastq"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted_tmp.sam"),
        unsorted_bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam")
    params:
        band_width = config["ex_remap_dsc"]["band_width"],
        clipping_penalty = config["ex_remap_dsc"]["clipping_penalty"],
        gap_extension_penalty = config["ex_remap_dsc"]["gap_extension_penalty"],
        gap_open_penalty = config["ex_remap_dsc"]["gap_open_penalty"],
        matching_score = config["ex_remap_dsc"]["matching_score"],
        mem_max_occurances = config["ex_remap_dsc"]["mem_max_occurances"],
        min_alignment_score_thresh = config["ex_remap_dsc"]["min_alignment_score_thresh"],
        min_seed_length = config["ex_remap_dsc"]["min_seed_length"],
        mismatch_penalty = config["ex_remap_dsc"]["mismatch_penalty"],
        reseed_factor = config["ex_remap_dsc"]["reseed_factor"],
        unpaired_read_penalty = config["ex_remap_dsc"]["unpaired_read_penalty"],
        z_dropoff = config["ex_remap_dsc"]["z_dropoff"]
    log:
        "logs/{ex_sample}/ex_remap_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_remap_dsc.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        samtools fastq -0 {output.intermediate_fastq} {input.bam} 2>> {log}

        bwa-mem2 mem \
        -t {threads} \
        -k {params.min_seed_length} \
        -w {params.band_width} \
        -d {params.z_dropoff} \
        -r {params.reseed_factor} \
        -c {params.mem_max_occurances} \
        -A {params.matching_score} \
        -B {params.mismatch_penalty} \
        -O {params.gap_open_penalty} \
        -E {params.gap_extension_penalty} \
        -L {params.clipping_penalty} \
        -U {params.unpaired_read_penalty} \
        -T {params.min_alignment_score_thresh} \
        -Y \
        {input.ref} {output.intermediate_fastq} > {output.intermediate_sam} 2>> {log}

        samtools view -@ {threads} -bS {output.intermediate_sam} > {output.unsorted_bam} 2>> {log}

        samtools sort -n -@ {threads} -o {output.bam} {output.unsorted_bam} 2>> {log}
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
    params:
        min_mapq = config["ex_filter_dsc"]["min_mapq"]
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
    - Remove reads with low MAPQ
"""
rule ex_filter_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"
    output:
        intermediate_bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered_unsorted.bam"),
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai")
    params:
        min_mapq = config["ex_filter_dsc"]["min_mapq"]
    log:
        "logs/{ex_sample}/ex_filter_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"
    shell:
        """
        samtools view -b \
        --min-MQ {params.min_mapq} \
        {input.bam} > {output.intermediate_bam} 2>> {log}
        
        samtools sort -o {output.bam} {output.intermediate_bam} 2>> {log}
        
        samtools index {output.bam} 2>> {log}
        """