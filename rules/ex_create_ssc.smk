"""
--- ex_create_ssc.smk ---

Rules for creating a single strand consensus from aligned BAM

Input: Reads aligned to reference genome (BAM), for experimental samples
Output: Same as input, but PCR duplicates collapsed

Author: James Phie

"""

rule exp_umitag:
    input:
        bam = "tmp/{sample}/{sample}_map.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi1.bam")
    threads:
        ncores
    resources:
        mem = 32
    shell:
        """
        #Move UMI from readname to RX:Z: tag and sort by name for UMI consensus steps
        fgbio \
            -Xmx{resources.mem}g \
            CopyUmiFromReadName \
            -i {input.bam} \
            -o /dev/stdout \
            --remove-umi true | \
        samtools sort -n -@ {threads} -o {output.bam}
        """

rule exp_addmate:
    input:
        bam = "tmp/{sample}/{sample}_map_umi1.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi2.bam")
    shell:
        """
        fgbio SetMateInformation \
        -i {input.bam} \
        -o {output.bam}
        """

rule exp_groupbyumi:
    input:
        bam = "tmp/{sample}/{sample}_map_umi2.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_umi3.bam"),
        histogram = "metrics/{sample}/{sample}_map_umi3_metrics.txt"
    threads:
        ncores
    resources:
        mem = 32
    shell:
        """
        fgbio \
            -Xmx{resources.mem}g \
            --compression 1 --async-io \
            GroupReadsByUmi \
            --min-umi-length 6 \
            -i {input.bam} \
            -o {output.bam} \
            -f {output.histogram} \
            -@ {threads} \
            -m 0 \
            --strategy=adjacency
        """

rule exp_ssc:
    input:
        bam = "tmp/{sample}/{sample}_map_umi3.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_unmap_ssc.bam")
    resources:
        mem = 32
    shell:
        """
        fgbio \
            -Xmx{resources.mem}g \
            --compression 1 CallMolecularConsensusReads \
            -i {input.bam} \
            -o {output.bam} \
            --consensus-call-overlapping-bases false \
            -M 1
        """

rule exp_addrg:
    input:
        bam = "tmp/{sample}/{sample}_unmap_ssc.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_unmap_ssc_rg.bam")
    params:
        sample = lambda wildcards: wildcards.sample
    shell:
        """
        picard AddOrReplaceReadGroups \
            I={input.bam} \
            O={output.bam} \
            RGID={params.sample} \
            RGLB=lib1 \
            RGPL=illumina \
            RGPU=unit1 \
            RGSM={params.sample} \
            VALIDATION_STRINGENCY=LENIENT
        """

rule exp_map_ssc:
    input:
        bam = "tmp/{sample}/{sample}_unmap_ssc_rg.bam"
    output:
        bam = temp("tmp/{sample}/{sample}_map_ssc.bam")
    threads: 
        ncores
    params:
        reference = REF,
    shell:
        """
        samtools fastq {input.bam} \
        | bwa-mem2 mem \
        -t {threads} \
        -p \
        -Y \
        {params.reference} - \
        | samtools view -b - -o {output}
        """

rule exp_zipdata: 
    input:
        mapped = "tmp/{sample}/{sample}_map_ssc.bam",
        unmapped = "tmp/{sample}/{sample}_unmap_ssc_rg.bam",
    output:
        bam = temp("tmp/{sample}/{sample}_map_ssc_anno.bam"),
        bai = temp("tmp/{sample}/{sample}_map_ssc_anno.bam.bai")
    params:
        reference = REF,
    resources:
        mem = 4,
    threads:
        ncores
    shell:
        """
        fgbio -Xmx{resources.mem}g -Djava.io.tmpdir={tmpdir} \
            --compression 0 --async-io ZipperBams \
            -i {input.mapped} \
            --unmapped {input.unmapped} \
            --ref {params.reference} \
            --tags-to-revcomp Consensus \
        | samtools sort - -o {output.bam} -O BAM -@ {threads} \
        && samtools index {output.bam} -@ {threads}
        """

rule exp_sscinsert_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map_ssc_anno.bam",
    output:
        txt = "metrics/{sample}/{sample}_map_ssc_insert_metrics.txt",
        hist = "metrics/{sample}/{sample}_map_ssc_insert_metrics.pdf",
    resources:
        mem = 32
    shell:
        """
        mkdir -p {tmpdir}
        picard \
            -Xmx{resources.mem}g \
            -Djava.io.tmpdir={tmpdir} \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100
        """

rule exp_sscdepth_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map_ssc_anno.bam",
    output:
        metrics = "metrics/{sample}/{sample}_ssc_depth_metrics.txt",
    params:
        ref = REF,
    resources:
        mem = 30,
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp/picard \
            CollectWgsMetrics \
            I={input.bam} \
            O={output.metrics} \
            R={params.ref} \
            INCLUDE_BQ_HISTOGRAM=true \
            MINIMUM_BASE_QUALITY=30
        """
    
rule exp_duplication_metrics:
    input:
        expand("metrics/{sample}/{sample}_map_umi3_metrics.txt", sample=sample_names)
    output:
        "metrics/duplication_metrics.txt"
    script:
        "scripts/duplication.py"
