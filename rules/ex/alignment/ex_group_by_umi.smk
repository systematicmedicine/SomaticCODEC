"""
Group reads by UMI and alignment
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_group_by_umi:
    input:
        bam = EX.MATE_INFO_BAM
    output:
        intermediate_moveumi = temp(EX.GROUP_BY_UMI_INT1),
        intermediate_moveumi_sorted = temp(EX.GROUP_BY_UMI_INT2),
        bam = temp(EX.UMI_GROUPED_BAM),
        umi_metrics = EX.MET_GROUP_BY_UMI,
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"],
        min_umi_length = config["sci_params"]["ex_group_by_umi"]["min_umi_length"]
    log:
        L.EX_GROUP_BY_UMI
    benchmark:
        "logs/{ex_sample}/ex_group_by_umi.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """        
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
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