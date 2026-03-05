"""
Add metadata to the DSC
    - Replace metadata lost during alignment
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_annotate_dsc: 
    input:
        # DSCs
        mapped = EX.REALIGNED_DSC,
        unmapped = EX.RAW_DSC,

        # Reference genome
        ref = config["sci_params"]["shared"]["reference_genome"],
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai",
        dictf = os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict"
    output:
        intermediate_anno = temp(EX.ANNOTATE_DSC_INT1),
        bam = temp(EX.ANNOTATED_DSC),
        bai = temp(EX.ANNOTATED_DSC_INDEX),
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.EX_ANNOTATE_DSC
    benchmark:
        "logs/{ex_sample}/ex_annotate_dsc.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    threads:
        config["infrastructure"]["threads"]["heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Transer metadata from unmapped BAM to mapped BAM
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            --async-io \
            ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {input.ref} \
            --tags-to-revcomp Consensus \
            -o {output.intermediate_anno} 2>> {log}

        # Sort BAM by coordinate
        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -@ {threads} \
        -o {output.bam} \
        {output.intermediate_anno} 2>> {log}

        # Index BAM
        samtools index -@ {threads} {output.bam} 2>> {log}
        """