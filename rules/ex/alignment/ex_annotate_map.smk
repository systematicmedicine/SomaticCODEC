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
        intermediate_collated = temp("tmp/{ex_sample}/{ex_sample}_map_collated_tmp.bam")
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

        # Group reads by name for samtools fixmate
        samtools collate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.intermediate_collated} \
        {output.intermediate_read_group} 2>> {log}

        # Add mate information to flags/CIGAR strings for read pairs
        samtools fixmate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -m {output.intermediate_collated} \
        {output.bam} 2>> {log}
        """