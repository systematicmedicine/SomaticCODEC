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
        ref = config["files"]["reference_genome"],
        amb = config["files"]["reference_genome"] + ".amb",
        ann = config["files"]["reference_genome"] + ".ann",
        bwt = config["files"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["files"]["reference_genome"] + ".pac",
        sa = config["files"]["reference_genome"] + ".0123"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map.bam"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_tmp.sam")
    params:
        band_width = config["rules"]["ex_map"]["band_width"],
        clipping_penalty = config["rules"]["ex_map"]["clipping_penalty"],
        gap_extension_penalty = config["rules"]["ex_map"]["gap_extension_penalty"],
        gap_open_penalty = config["rules"]["ex_map"]["gap_open_penalty"],
        matching_score = config["rules"]["ex_map"]["matching_score"],
        mem_max_occurances = config["rules"]["ex_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["rules"]["ex_map"]["min_alignment_score_thresh"],
        min_seed_length = config["rules"]["ex_map"]["min_seed_length"],
        mismatch_penalty = config["rules"]["ex_map"]["mismatch_penalty"],
        reseed_factor = config["rules"]["ex_map"]["reseed_factor"],
        unpaired_read_penalty = config["rules"]["ex_map"]["unpaired_read_penalty"],
        z_dropoff = config["rules"]["ex_map"]["z_dropoff"],
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_map.log"
    benchmark:
        "logs/{ex_sample}/ex_map.benchmark.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
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
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_filter_map.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_map.benchmark.txt"
    threads: 
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
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
        histogram = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt",
        intermediate_moveumi = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_tmp.bam"),
        intermediate_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_sorted_tmp.bam"),
        intermediate_mateinfo = temp("tmp/{ex_sample}/{ex_sample}_map_mateinfo_tmp.bam"),
        intermediate_groupbyumi = temp("tmp/{ex_sample}/{ex_sample}_map_groupbyumi_tmp.bam"),
        intermediate_anno_unsorted = temp("tmp/{ex_sample}/{ex_sample}_map_anno_unsorted.bam")
    params:
        min_umi_length = config["rules"]["ex_annotate_map"]["min_umi_length"],
        compression_level = config["file_compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_annotate_map.log"
    benchmark:
        "logs/{ex_sample}/ex_annotate_map.benchmark.txt"
    threads:
        config["resources"]["threads"]["heavy"]
    resources:
        memory = config["resources"]["memory"]["heavy"]
    shell:
        """
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            CopyUmiFromReadName \
            --compression={params.compression_level} \
            -i {input.bam} \
            -o {output.intermediate_moveumi} \
            --remove-umi true 2>> {log}

        samtools sort \
            -n \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            -o {output.intermediate_sorted} \
            {output.intermediate_moveumi} 2>> {log}

        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            SetMateInformation \
            --compression={params.compression_level} \
            -i {output.intermediate_sorted} \
            -o {output.intermediate_mateinfo} 2>> {log}

        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression 1 \
            GroupReadsByUmi \
            --compression={params.compression_level} \
            --min-umi-length {params.min_umi_length} \
            -i {output.intermediate_mateinfo} \
            -o {output.intermediate_groupbyumi} \
            -f {output.histogram} \
            -@ {threads} \
            -m 0 \
            --strategy=adjacency 2>> {log}

        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
            AddOrReplaceReadGroups \
            --COMPRESSION_LEVEL={params.compression_level} \
            I={output.intermediate_groupbyumi} \
            O={output.intermediate_anno_unsorted} \
            RGID={wildcards.ex_sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={wildcards.ex_sample} \
            VALIDATION_STRINGENCY=LENIENT 2>> {log}

        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            SortBam \
            --compression={params.compression_level} \
            -i {output.intermediate_anno_unsorted} \
            -o {output.bam} \
            -s TemplateCoordinate 2>> {log}
        """
        