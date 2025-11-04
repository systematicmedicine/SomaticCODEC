# Annotates aligned reads for downstream rules
#   - Adds read group information for picard metrics
#   - Adds ms and MC tags for samtools markdup

rule ms_annotate_map:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_raw_map.bam"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_annotated_map.bam"),
        bai = temp("tmp/{ms_sample}/{ms_sample}_annotated_map.bam.bai"),
        intermediate_uncollated = temp("tmp/{ms_sample}/{ms_sample}_annotated_map_uncollated.bam"),
        intermediate_collated = temp("tmp/{ms_sample}/{ms_sample}_annotated_map_collated.bam"),
        intermediate_fixmate = temp("tmp/{ms_sample}/{ms_sample}_annotated_map_fixmate.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_annotate_map.log"
    benchmark:
        "logs/{ms_sample}/ms_annotate_map.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp AddOrReplaceReadGroups \
            --INPUT {input.bam} \
            --OUTPUT {output.intermediate_uncollated} \
            --COMPRESSION_LEVEL {params.compression_level} \
            --RGID {wildcards.ms_sample} \
            --RGLB {wildcards.ms_sample}_lib \
            --RGPL ILLUMINA \
            --RGPU {wildcards.ms_sample} \
            --RGSM {wildcards.ms_sample} 2>> {log}

        samtools collate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.intermediate_collated} \
        {output.intermediate_uncollated} 2>> {log}

        samtools fixmate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -m {output.intermediate_collated} \
        {output.intermediate_fixmate} 2>> {log}

        samtools sort \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_fixmate} 2>> {log}

        samtools index {output.bam} 2>> {log}
        """