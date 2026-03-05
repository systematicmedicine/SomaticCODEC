"""
 Adds read mate information to flags/CIGAR strings of mapped reads
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_add_mate_information:
    input:
        bam = EX.READ_GROUP_BAM
    output:
        intermediate_collated = temp(EX.ADD_MATE_INFORMATION_INT),
        bam = temp(EX.MATE_INFO_BAM),
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.EX_ADD_MATE_INFORMATION
    benchmark:
        "logs/{ex_sample}/ex_add_mate_information.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
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