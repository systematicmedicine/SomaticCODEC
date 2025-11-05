"""
Add metadata to the DSC
    - Replace metadata lost during alignment
"""
rule ex_annotate_dsc: 
    input:
        mapped = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
        unmapped = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam",
        ref = config["sci_params"]["global"]["reference_genome"],
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai",
        dictf = os.path.splitext(config["sci_params"]["global"]["reference_genome"])[0] + ".dict"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam"),
        bai = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam.bai"),
        intermediate_anno = temp("tmp/{ex_sample}/{ex_sample}_map_dsc_anno_unsorted_tmp.bam")
    params:
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_annotate_dsc.log"
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