"""
 Adds read group information to mapped reads for downstream rules
    - All reads are given the same read group
"""

from definitions.paths.io import ex as EX

rule ex_add_read_groups:
    input:
        bam = EX.FILTERED_BAM,
        dictf = os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict"
    output:
        bam = temp(EX.READ_GROUP_BAM)
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_add_read_groups.log"
    benchmark:
        "logs/{ex_sample}/ex_add_read_groups.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit and add read group information
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
            AddOrReplaceReadGroups \
            --COMPRESSION_LEVEL {params.compression_level} \
            --INPUT {input.bam} \
            --OUTPUT {output.bam} \
            --RGID {wildcards.ex_sample} \
            --RGLB lib1 \
            --RGPL illumina \
            --RGPU unit1 \
            --RGSM {wildcards.ex_sample} \
            --VALIDATION_STRINGENCY LENIENT 2>> {log}
        """