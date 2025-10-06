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
    - Remove read pairs that are on different chromosomes
    - Remove reads pairs that are too far apart (~500bp, determined by aligner)
    - Remove read pairs that are not read in the correct directions
"""
rule ex_filter_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_correct.bam"),
        intermediate_unsorted = temp("tmp/{ex_sample}/{ex_sample}_map_correct_unsorted.bam")
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
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        {input.bam} > {output.intermediate_unsorted} 2>> {log}

        samtools sort \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_unsorted} 2>> {log}
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
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt",
        intermediate_readgroup = temp("tmp/{ex_sample}/{ex_sample}_map_readgroup_tmp.bam"),
        intermediate_moveumi = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_tmp.bam"),
        intermediate_moveumi_primary = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_primary_tmp.bam"),
        intermediate_moveumi_primary_index = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_primary_tmp.bam.bai"),
        intermediate_groupbyumi = temp("tmp/{ex_sample}/{ex_sample}_map_groupbyumi_tmp.bam"),
        intermediate_groupbyumi_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_groupbyumi_sorted_tmp.bam"),
        intermediate_groupbyumi_MI_tag = temp("tmp/{ex_sample}/{ex_sample}_map_groupbyumi_MI_tag_tmp.bam"),
        intermediate_mateinfo = temp("tmp/{ex_sample}/{ex_sample}_map_mateinfo_tmp.bam"),
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
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
            AddOrReplaceReadGroups \
            --COMPRESSION_LEVEL {params.compression_level} \
            --INPUT {input.bam} \
            --OUTPUT {output.intermediate_readgroup} \
            --RGID {wildcards.ex_sample} \
            --RGLB lib1 \
            --RGPL illumina \
            --RGPU unit1 \
            --RGSM {wildcards.ex_sample} \
            --VALIDATION_STRINGENCY LENIENT 2>> {log}
        
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            CopyUmiFromReadName \
            -i {output.intermediate_readgroup} \
            -o {output.intermediate_moveumi} \
            --remove-umi true 2>> {log}

        samtools view \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -F 0x900 \
            {output.intermediate_moveumi} > \
            {output.intermediate_moveumi_primary} 2>> {log}

        samtools index {output.intermediate_moveumi_primary} 2>> {log}
        
        umi_tools group \
            --stdin={output.intermediate_moveumi_primary} \
            --output-bam \
            --compresslevel={params.compression_level} \
            --no-sort-output \
            --stdout={output.intermediate_groupbyumi} \
            --group-out={output.umi_metrics} \
            --extract-umi-method=tag \
            --umi-tag=RX \
            --paired \
            --method=directional 2>> {log}

        samtools sort \
            -n \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -o {output.intermediate_groupbyumi_sorted} \
            {output.intermediate_groupbyumi} 2>> {log}

        python scripts/ex_rename_umi_bam_tag.py \
            --input {output.intermediate_groupbyumi_sorted} \
            --output {output.intermediate_groupbyumi_MI_tag} 2>> {log}

        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            SetMateInformation \
            -i {output.intermediate_groupbyumi_MI_tag} \
            -o {output.intermediate_mateinfo} 2>> {log}

        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            SortBam \
            -i {output.intermediate_mateinfo} \
            -o {output.bam} \
            -s TemplateCoordinate 2>> {log}
        """
        