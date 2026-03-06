"""
 Adds read mate information to flags/CIGAR strings of mapped reads
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_add_mate_information:
    input:
        bam = MS.READ_GROUP_BAM
    output:
        intermediate_collated = temp(MS.ADD_MATE_INFORMATION_INT1),
        intermediate_unsorted = temp(MS.ADD_MATE_INFORMATION_INT2),
        bam = temp(MS.MATE_INFO_BAM),
        bai = temp(MS.MATE_INFO_BAM_INDEX),
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.MS_ADD_MATE_INFORMATION
    benchmark:
        B.MS_ADD_MATE_INFORMATION
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