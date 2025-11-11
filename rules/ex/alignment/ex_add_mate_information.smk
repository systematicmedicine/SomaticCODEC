"""
 Adds read mate information to flags/CIGAR strings of mapped reads
"""
rule ex_add_mate_information:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_read_group.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_anno.bam"),
        intermediate_collated = temp("tmp/{ex_sample}/{ex_sample}_map_collated_tmp.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_add_mate_information.log"
    benchmark:
        "logs/{ex_sample}/ex_add_mate_information.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Group reads by name for samtools fixmate
        samtools collate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.intermediate_collated} \
        {input.bam} 2>> {log}

        # Add mate information to flags/CIGAR strings for read pairs
        samtools fixmate \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -m {output.intermediate_collated} \
        {output.bam} 2>> {log}
        """