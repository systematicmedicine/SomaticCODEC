"""
Filter mapped reads
    - Remove reads without 0x2 (properly paired) flag, i.e.:
        - Read pairs that are on different chromosomes
        - Read pairs that are too far apart (~500bp, determined by aligner)
        - Read pairs that are not read in the correct directions
    - Remove read pairs with 0x100, 0x800 and 0x4 flags, i.e.:
        - Secondary alignments
        - Supplementary alignments
        - Unmapped reads
"""
rule ex_filter_map:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_correct.bam")
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
        -F 0x904 \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        {input.bam} > {output.bam} 2>> {log}
        """