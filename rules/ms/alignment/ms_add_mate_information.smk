"""
 Adds read mate information to flags/CIGAR strings of mapped reads
"""
rule ms_add_mate_information:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_annotated_map.bam"),
        bai = temp("tmp/{ms_sample}/{ms_sample}_annotated_map.bam.bai"),
        intermediate_collated = temp("tmp/{ms_sample}/{ms_sample}_read_group_map_collated.bam"),
        intermediate_unsorted = temp("tmp/{ms_sample}/{ms_sample}_fixmate_map_unsorted.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_add_mate_information.log"
    benchmark:
        "logs/{ms_sample}/ms_add_mate_information.benchmark.txt"
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
        -m \
        {output.intermediate_collated} \
        {output.intermediate_unsorted} 2>> {log}

        # Sort annotated BAM
        samtools sort \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_unsorted} 2>> {log}

        # Create index for annotated BAM
        samtools index {output.bam} 2>> {log}
        """