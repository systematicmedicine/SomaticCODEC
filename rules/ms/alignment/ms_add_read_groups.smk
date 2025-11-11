"""
 Adds read group information to mapped reads for downstream rules
    - All reads are given the same read group
"""
rule ms_add_read_groups:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_raw_map.bam"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_read_group_map.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_add_read_groups.log"
    benchmark:
        "logs/{ms_sample}/ms_add_read_groups.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """
        # Set memory limit and add read group information
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp AddOrReplaceReadGroups \
            --INPUT {input.bam} \
            --OUTPUT {output.bam} \
            --COMPRESSION_LEVEL {params.compression_level} \
            --RGID {wildcards.ms_sample} \
            --RGLB {wildcards.ms_sample}_lib \
            --RGPL ILLUMINA \
            --RGPU {wildcards.ms_sample} \
            --RGSM {wildcards.ms_sample} 2>> {log}
        """