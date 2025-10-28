"""
Filter reads from DSC
    - Remove reads with low MAPQ
"""
rule ex_filter_dsc:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"
    output:
        intermediate_bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered_unsorted.bam"),
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai")
    params:
        min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_filter_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_filter_dsc.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        samtools view \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -b \
        -@ {threads} \
        --min-MQ {params.min_mapq} \
        {input.bam} > {output.intermediate_bam} 2>> {log}
        
        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_bam} 2>> {log}
        
        samtools index {output.bam} 2>> {log}
        """