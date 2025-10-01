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
    - Joshua Johnstone
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
        error_rate_pre_umi = config["rules"]["ex_call_dsc"]["error_rate_pre_umi"],
        error_rate_post_umi = config["rules"]["ex_call_dsc"]["error_rate_post_umi"],
        min_input_base_quality = config["rules"]["ex_call_dsc"]["min_input_base_quality"],
        min_read_pairs = config["rules"]["ex_call_dsc"]["min_read_pairs"],
        min_duplex_length = config["rules"]["ex_call_dsc"]["min_duplex_length"],
        max_duplex_disagreement_rate = config["rules"]["ex_call_dsc"]["max_duplex_disagreement_rate"],
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_call_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_call_dsc.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
         CallCodecConsensusReads \
            --compression={params.compression_level} \
            -i {input.bam} \
            -o {output.bam} \
            --error-rate-pre-umi {params.error_rate_pre_umi} \
            --error-rate-post-umi {params.error_rate_post_umi} \
            --min-input-base-quality {params.min_input_base_quality} \
            --min-read-pairs {params.min_read_pairs} \
            --min-duplex-length {params.min_duplex_length} \
            --max-duplex-disagreement-rate {params.max_duplex_disagreement_rate} \
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
        ref = config["files"]["reference_genome"],
        amb = config["files"]["reference_genome"] + ".amb",
        ann = config["files"]["reference_genome"] + ".ann",
        bwt = config["files"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["files"]["reference_genome"] + ".pac",
        sa = config["files"]["reference_genome"] + ".0123"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc.bam"),
        intermediate_fastq = temp("tmp/{ex_sample}/{ex_sample}_unmap_dsc_tmp.fastq"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted_tmp.sam"),
        unsorted_bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam")
    params:
        band_width = config["rules"]["ex_remap_dsc"]["band_width"],
        clipping_penalty = config["rules"]["ex_remap_dsc"]["clipping_penalty"],
        gap_extension_penalty = config["rules"]["ex_remap_dsc"]["gap_extension_penalty"],
        gap_open_penalty = config["rules"]["ex_remap_dsc"]["gap_open_penalty"],
        matching_score = config["rules"]["ex_remap_dsc"]["matching_score"],
        mem_max_occurances = config["rules"]["ex_remap_dsc"]["mem_max_occurances"],
        min_alignment_score_thresh = config["rules"]["ex_remap_dsc"]["min_alignment_score_thresh"],
        min_seed_length = config["rules"]["ex_remap_dsc"]["min_seed_length"],
        mismatch_penalty = config["rules"]["ex_remap_dsc"]["mismatch_penalty"],
        reseed_factor = config["rules"]["ex_remap_dsc"]["reseed_factor"],
        unpaired_read_penalty = config["rules"]["ex_remap_dsc"]["unpaired_read_penalty"],
        z_dropoff = config["rules"]["ex_remap_dsc"]["z_dropoff"],
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_remap_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_remap_dsc.benchmark.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        samtools fastq \
        -0 \
        {output.intermediate_fastq} \
        {input.bam} 2>> {log}

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
        {input.ref} \
        {output.intermediate_fastq} > {output.intermediate_sam} 2>> {log}

        samtools view \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -@ {threads} \
        -bS \
        {output.intermediate_sam} > {output.unsorted_bam} 2>> {log}

        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -n \
        -@ {threads} \
        -o {output.bam} \
        {output.unsorted_bam} 2>> {log}
        """


"""
Add metadata to the DSC
    - Replace metadata lost during alignment
"""
rule ex_annotate_dsc: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam",
        ref = config["files"]["reference_genome"],
        fai = config["files"]["reference_genome"] + ".fai",
        dictf = os.path.splitext(config["files"]["reference_genome"])[0] + ".dict"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai"),
        intermediate_anno = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_tmp.bam")
    params:
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_annotate_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_annotate_dsc.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    threads:
        config["resources"]["threads"]["heavy"]
    shell:
        """
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            ZipperBams \
            --compression={params.compression_level} \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {input.ref} \
            --tags-to-revcomp Consensus \
            -o {output.intermediate_anno} 2>> {log}

        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -@ {threads} \
        -o {output.bam} \
        {output.intermediate_anno} 2>> {log}

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
        min_mapq = config["rules"]["ex_filter_dsc"]["min_mapq"]
    log:
        "logs/{ex_sample}/ex_filter_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        samtools view \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -b \
        -@ {threads} \
        --min-MQ {params.min_mapq} \
        {input.bam} > {output.intermediate_bam} 2>> {log}
        
        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_bam} 2>> {log}
        
        samtools index {output.bam} 2>> {log}
        """