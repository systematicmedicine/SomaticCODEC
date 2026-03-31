"""
 Adds read group information to mapped reads for downstream rules
    - All reads are given the same read group
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_add_read_groups:
    input:
        bam = MS.RAW_BAM,
        dictf = os.path.splitext(config["sci_params"]["reference_files"]["genome"])[0] + ".dict"
    output:
        bam = temp(MS.READ_GROUP_BAM)
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.MS_ADD_READ_GROUPS
    benchmark:
        B.MS_ADD_READ_GROUPS
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