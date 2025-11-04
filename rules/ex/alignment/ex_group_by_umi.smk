"""
Group reads by UMI and alignment
"""
rule ex_group_by_umi:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_umi_grouped.bam"),
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt",
        intermediate_moveumi = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_tmp.bam"),
        intermediate_moveumi_sorted = temp("tmp/{ex_sample}/{ex_sample}_map_moveumi_sorted_tmp.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"],
        min_umi_length = config["sci_params"]["ex_group_by_umi"]["min_umi_length"]
    log:
        "logs/{ex_sample}/ex_group_by_umi.log"
    benchmark:
        "logs/{ex_sample}/ex_group_by_umi.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """        
        # Move UMI from read name to RX:Z tag
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o {output.intermediate_moveumi} \
            --remove-umi true 2>> {log}

        # Sort by template-coordinate for fgbio GroupReadsByUmi
        samtools sort \
            -@ {threads} \
            --output-fmt bam \
            --output-fmt-option level={params.compression_level} \
            --template-coordinate \
            -o {output.intermediate_moveumi_sorted} \
            {output.intermediate_moveumi} 2>> {log}

        # Group reads by UMI and alignment
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            --async-io \
            GroupReadsByUmi \
            --min-umi-length {params.min_umi_length} \
            -i {output.intermediate_moveumi_sorted} \
            -o {output.bam} \
            -f {output.umi_metrics} \
            -m 0 \
            --strategy=adjacency 2>> {log} 
        """