"""
--- ex_alignment.smk ---

Rules for aligning umapped, non-deduplicated reads to reference genome, for experimental samples

Input: Processed (demuxed, trimmed and length filtered) FASTQ files
Output: Reads aligned to a reference genome (BAM) 

Authors: 
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
"""

"""
Map reads to reference genome
"""
rule ex_map:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz",
        ref = config["sci_params"]["global"]["reference_genome"],
        amb = config["sci_params"]["global"]["reference_genome"] + ".amb",
        ann = config["sci_params"]["global"]["reference_genome"] + ".ann",
        bwt = config["sci_params"]["global"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["sci_params"]["global"]["reference_genome"] + ".pac",
        sa = config["sci_params"]["global"]["reference_genome"] + ".0123"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map.bam"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_tmp.sam")
    params:
        band_width = config["sci_params"]["ex_map"]["band_width"],
        clipping_penalty = config["sci_params"]["ex_map"]["clipping_penalty"],
        gap_extension_penalty = config["sci_params"]["ex_map"]["gap_extension_penalty"],
        gap_open_penalty = config["sci_params"]["ex_map"]["gap_open_penalty"],
        matching_score = config["sci_params"]["ex_map"]["matching_score"],
        mem_max_occurances = config["sci_params"]["ex_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["sci_params"]["ex_map"]["min_alignment_score_thresh"],
        min_seed_length = config["sci_params"]["ex_map"]["min_seed_length"],
        mismatch_penalty = config["sci_params"]["ex_map"]["mismatch_penalty"],
        reseed_factor = config["sci_params"]["ex_map"]["reseed_factor"],
        unpaired_read_penalty = config["sci_params"]["ex_map"]["unpaired_read_penalty"],
        z_dropoff = config["sci_params"]["ex_map"]["z_dropoff"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_map.log"
    benchmark:
        "logs/{ex_sample}/ex_map.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
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
        {input.fastq1} {input.fastq2} > {output.intermediate_sam} 2>> {log}

        samtools view \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """


"""
Filter mapped reads
    - Remove reads without 0x2 (properly paired) flag, i.e.:
        - Read pairs that are on different chromosomes
        - Read pairs that are too far apart (~500bp, determined by aligner)
        - Read pairs that are not read in the correct directions
    - Remove read pairs with 0x100, 0x800 and 0x4 flags, i.e.:
        - Secondary alignments
        - Supplementary alignments
        - Unmapped reads
"""
rule ex_filter_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_correct.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_filter_map.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_map.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        samtools view \
        -@ {threads} \
        -b \
        -f 0x2 \
        -F 0x904 \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        {input.bam} > {output.bam} 2>> {log}
        """


"""
 Annotate the mapped reads for downstream rules
    - Add read group information (all reads given same read group)
    - Add read mate information to flags/CIGAR strings
"""
rule ex_annotate_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_anno.bam"),
        intermediate_read_group = temp("tmp/{ex_sample}/{ex_sample}_map_read_group_tmp.bam"),
        intermediate_read_group_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_read_group_sorted_tmp.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_annotate_map.log"
    benchmark:
        "logs/{ex_sample}/ex_annotate_map.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """
        # Add read group information (all reads given same read group)
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
            AddOrReplaceReadGroups \
            --COMPRESSION_LEVEL {params.compression_level} \
            --INPUT {input.bam} \
            --OUTPUT {output.intermediate_read_group} \
            --RGID {wildcards.ex_sample} \
            --RGLB lib1 \
            --RGPL illumina \
            --RGPU unit1 \
            --RGSM {wildcards.ex_sample} \
            --VALIDATION_STRINGENCY LENIENT 2>> {log}

        # Sort by query name for fgbio SetMateInformation
        samtools sort \
            -n \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -o {output.intermediate_read_group_sorted} \
            {output.intermediate_read_group} 2>> {log}

        # Add mate information to flags/CIGAR strings for read pairs
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            SetMateInformation \
            -i {output.intermediate_read_group_sorted} \
            -o {output.bam} 2>> {log}
        """

"""
Group reads by UMI
    - Identify groups of reads with same/similar UMI (determined by umitools directional method)
    - Add UMI groups to UG:i tag
    - Move UMI from UG:i tag to MI:Z tag
"""
rule ex_group_by_umi:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi_grouped.bam"),
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt",
        intermediate_moveumi = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_tmp.bam"),
        intermediate_moveumi_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_sorted_tmp.bam"),
        intermediate_moveumi_sorted_index = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_sorted_tmp.bam.bai"),
        intermediate_umi_group_UG = temp("tmp/{ex_sample}/{ex_sample}_map_umi_group_UG_tmp.bam"),
        intermediate_umi_group_UG_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_umi_group_UG_sorted_tmp.bam"),
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_group_by_umi.log"
    benchmark:
        "logs/{ex_sample}/ex_group_by_umi.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """        
        # Move UMI from read name to RX:Z tag
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o {output.intermediate_moveumi} \
            --remove-umi true 2>> {log}

        # Sort by coordinate for umi_tools group
        samtools sort \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -o {output.intermediate_moveumi_sorted} \
            {output.intermediate_moveumi} 2>> {log}

        # Index BAM for umi_tools group
        samtools index {output.intermediate_moveumi_sorted} 2>> {log}

        # Group reads by UMI and add UMI groups to UG:i tag
        umi_tools group \
            --stdin={output.intermediate_moveumi_sorted} \
            --output-bam \
            --compresslevel={params.compression_level} \
            --stdout={output.intermediate_umi_group_UG} \
            --no-sort-output \
            --group-out={output.umi_metrics} \
            --extract-umi-method=tag \
            --umi-tag=RX \
            --paired \
            --method=directional 2>> {log}  

        # Sort by query name for ex_rename_umi_bam_tag.py 
        samtools sort \
            -@ {threads} \
            -n \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -o {output.intermediate_umi_group_UG_sorted} \
            {output.intermediate_umi_group_UG} 2>> {log}

        # Move UMI group from UG:i tag to MI:Z tag as expected by consensus caller
        python scripts/ex_rename_umi_bam_tag.py \
            --input {output.intermediate_umi_group_UG_sorted} \
            --output {output.bam} 2>> {log} 
        """