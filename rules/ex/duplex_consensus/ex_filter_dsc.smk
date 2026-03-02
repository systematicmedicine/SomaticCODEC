"""
Filter reads from DSC
    - Remove reads with low MAPQ
"""

from definitions.paths.io import ex as EX

rule ex_filter_dsc:
    input:
        bam = EX.ANNOTATED_DSC
    output:
        intermediate_bam = temp(EX.FILTER_DSC_INT1),
        bam = temp(EX.FILTERED_DSC),
        bai = temp(EX.FILTERED_DSC_INDEX)
    params:
        min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_filter_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Filter BAM
        samtools view \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -b \
        -@ {threads} \
        --min-MQ {params.min_mapq} \
        {input.bam} > {output.intermediate_bam} 2>> {log}
        
        # Sort BAM by coordinate
        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_bam} 2>> {log}
        
        # Index BAM
        samtools index {output.bam} 2>> {log}
        """