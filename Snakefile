import pandas as pd
from Bio import SeqIO

# Load config
workdir: config["cwd"]
REF = config['ref']
EVAL_REGION_BED = config['region_bed']
EVAL_REGION_IL = config['region_interval_list']
DBSNP = config['dbsnp']
tmpdir = config['tmpdir']
inputdata_file = config["input_meta"]
r1start = config["r1start"]
r2start = config["r2start"]
r1end = config["r1end"]
r2end = config["r2end"]
ncores = config["ncores"]

# Load sample metadata
inputdata = pd.read_csv(inputdata_file, sep="\t")
sample_names = list(inputdata["samplename"])
all_index_names = set(record.id for record in SeqIO.parse(r1start, "fasta"))
unused_indexes = sorted(all_index_names - set(sample_names))
raw_fastq1 = inputdata.iloc[0]["fastq1"]
raw_fastq2 = inputdata.iloc[0]["fastq2"]

rule all:
    input:
        "tmp/r1start.fasta",
        "tmp/r1end.fasta",
        "tmp/r2start.fasta",
        "tmp/r2end.fasta",
        "metrics/demux_metrics.txt",
        "metrics/demux_metrics.json",
        "metrics/sample_readcounts_metrics.txt",
        "metrics/batchcontamination_metrics.txt",
        "exp_correctproduct_metrics/correctproduct_metrics.txt",
        "exp_duplication_metrics/duplication_metrics.txt",
        expand("tmp/{sample}/{sample}_r1_raw.fastq.gz", sample=sample_names),
        expand("tmp/{sample}/{sample}_r2_raw.fastq.gz", sample=sample_names),
        expand("tmp/{sample}/{sample}_r1_trim.fastq.gz", sample=sample_names),
        expand("tmp/{sample}/{sample}_r2_trim.fastq.gz", sample=sample_names),
        expand("metrics/{sample}/{sample}_trim_metrics.txt", sample=sample_names),
        expand("tmp/{sample}/{sample}_r1_trimfilter.fastq.gz", sample=sample_names),
        expand("tmp/{sample}/{sample}_r2_trimfilter.fastq.gz", sample=sample_names),
        expand("metrics/{sample}/{sample}_trimfilter_metrics.txt", sample=sample_names),
        expand("metrics/{sample}/{sample}_r1_trimfilter_metrics.html", sample=sample_names),
        expand("metrics/{sample}/{sample}_r2_trimfilter_metrics.html", sample=sample_names),
        expand("tmp/{sample}/{sample}_map.bam", sample=sample_names),
        expand("metrics/{sample}/{sample}_map_metrics.txt", sample=sample_names),
        expand("tmp/{sample}/{sample}_map_umi1.bam", sample=sample_names),
        expand("tmp/{sample}/{sample}_map_umi3.bam", sample=sample_names),
        expand("metrics/{sample}/{sample}_map_umi3_metrics.txt", sample=sample_names),
        expand("tmp/{sample}/{sample}_unmap_ssc.bam", sample=sample_names),
        expand("tmp/{sample}/{sample}_unmap_ssc_rg.bam", sample=sample_names),
        expand("tmp/{sample}/{sample}_map_ssc.bam", sample=sample_names),
        expand("tmp/{sample}/{sample}_map_ssc_anno.bam", sample=sample_names),
        expand("tmp/{sample}/{sample}_map_ssc_anno.bam.bai", sample=sample_names),
        expand("metrics/{sample}/{sample}_map_ssc_insert_metrics.txt", sample=sample_names),
        expand("metrics/{sample}/{sample}_map_ssc_insert_metrics.pdf", sample=sample_names),
        expand("metrics/{sample}/{sample}_ssc_depth_metrics.txt", sample=sample_names)

rule exp_namesamples:
    input:
        r1start=r1start,
        r1end=r1end,
        r2start=r2start,
        r2end=r2end,
        mapping=inputdata_file,
    output:
        r1start_out="tmp/r1start.fasta",
        r1end_out="tmp/r1end.fasta",
        r2start_out="tmp/r2start.fasta",
        r2end_out="tmp/r2end.fasta"
    script:
        "scripts/samplenames.py"

rule exp_fastqcraw_metrics:
    input:
        fastq1 = raw_fastq1,
        fastq2 = raw_fastq2
    output:
        fastqc_report1 = "metrics/r1_fastqc_raw_metrics.html",
        fastqc_report2 = "metrics/r2_fastqc_raw_metrics.html"
    resources:
        mem = 8,
        runtime = 24
    shell:
        """
        fastqc {input.fastq1} -o metrics/
        fastqc {input.fastq2} -o metrics/

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        """
rule exp_demux:
    input:
        fastq1 = raw_fastq1,
        fastq2 = raw_fastq2,
        r1_start = "tmp/r1start.fasta",
        r2_start = "tmp/r2start.fasta"
    output:
        demuxed_r1 = temp(expand("tmp/{sample}/{sample}_r1_raw.fastq.gz", sample=sample_names)),
        demuxed_r2 = temp(expand("tmp/{sample}/{sample}_r2_raw.fastq.gz", sample=sample_names)),
        report = "metrics/demux_metrics.txt",
        json = "metrics/demux_metrics.json"
    threads:
        ncores
    shell:
        """
        #Trim the UMI (first 3 bases) of each read and append to read name
        #Demultiplex PE reads based on sample indice on read 1
        #Trim 5' sample indices from read 1 and read 2
        cutadapt \
          -j {threads} \
          --no-indels \
          -e 2 \
          -g ^file:{input.r1_start} \
          -G ^file:{input.r2_start} \
          --cut 3 \
          -U 3 \
          --pair-adapters \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o tmp/{{name}}_r1_raw.fastq.gz \
          -p tmp/{{name}}_r2_raw.fastq.gz \
          {input.fastq1} {input.fastq2} \
          --report=full > {output.report} \
          --json={output.json}
        """

rule exp_trim:
    input:
        r1 = "tmp/{sample}/{sample}_r1_raw.fastq.gz",
        r2 = "tmp/{sample}/{sample}_r2_raw.fastq.gz",
        r1_end = "tmp/r1end.fasta",
        r2_end = "tmp/r2end.fasta"
    output:
        r1 = temp("tmp/{sample}/{sample}_r1_trim.fastq.gz"),
        r2 = temp("tmp/{sample}/{sample}_r2_trim.fastq.gz"),
        report = "metrics/{sample}/{sample}_trim_metrics.txt",
        json = "metrics/{sample}/{sample}_trim_metrics.json"
    threads:
        ncores
    shell:
        """
        #Trim 1bp from 5' end (T from ligation)
        #Trim 3' indices/adapters
        cutadapt \
          -j {threads} \
          --cut 1 \
          -U 1 \
          -e 1 \
          -O 7 \
          -a file:{input.r1_end} \
          -A file:{input.r2_end} \
          -o {output.r1} \
          -p {output.r2} \
          {input.r1} {input.r2} \
          --report=full > {output.report} \
          --json={output.json}
        """

rule exp_trimfilter:
    input: 
        r1 = "tmp/{sample}/{sample}_r1_trim.fastq.gz",
        r2 = "tmp/{sample}/{sample}_r2_trim.fastq.gz",  
    output:
        r1 = temp("tmp/{sample}/{sample}_r1_trimfilter.fastq.gz"),
        r2 = temp("tmp/{sample}/{sample}_r2_trimfilter.fastq.gz"),
        report = "metrics/{sample}/{sample}_trimfilter_metrics.txt",
        json = "metrics/{sample}/{sample}_trimfilter_metrics.json"
    threads:
        ncores
    shell:  
        """
        #Trim 8 bases from 3' end of read 1 and read 2 to remove any remaining short (<7bp) sample indices.
        #8 base trimming could be relaxed as duplex seq will detect and filter adapters due to R1R2 disagree later. 
        #The trim also removes poly A-tails from ligation. 
        #Filter for insert length <15bp
        cutadapt \
        -j {threads} \
        -u -8 \
        -U -8 \
        -u 2 \
        -U 2 \
        --minimum-length 70 \
        --quality-cutoff 20 \
        -o {output.r1} \
        -p {output.r2} \
        {input.r1} {input.r2} \
        --report=full > {output.report} \
        --json={output.json}
        """

rule exp_fastqctrim_metrics:
    input:
        fastq1 = "tmp/{sample}/{sample}_r1_trimfilter.fastq.gz",
        fastq2 = "tmp/{sample}/{sample}_r2_trimfilter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{sample}/{sample}_r1_trimfilter_metrics.html",
        fastqc_report2 = "metrics/{sample}/{sample}_r2_trimfilter_metrics.html"
    shell:
        """
        fastqc {input.fastq1} -o metrics/{wildcards.sample}
        fastqc {input.fastq2} -o metrics/{wildcards.sample}

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1}
        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2}
        """

rule exp_align:
    input:
        fastq1 = "tmp/{sample}/{sample}_r1_trimfilter.fastq.gz",
        fastq2 = "tmp/{sample}/{sample}_r2_trimfilter.fastq.gz"
    output:
        bam = temp("tmp/{sample}/{sample}_map.bam")
    threads: 
        ncores
    params:
        reference = REF,
    shell:
        """
        #0x2 flag calculated based on ... first 256k high-confidence read pairs, >~500bp gap between R1R2 not properly paired
        bwa-mem2 mem \
            -t {threads} \
            -Y \
            {params.reference} {input.fastq1} {input.fastq2} | \
        samtools view -o {output.bam}
        """

rule exp_map_metrics:
    input:
        bam = "tmp/{sample}/{sample}_map.bam"
    output:
        txt = "metrics/{sample}/{sample}_map_metrics.txt"
    shell:
        """
        #Alternatively, picard's CollectAlignmentSummaryMetrics has more detailed metrics but will take much longer (?1 hour per sample vs ?2 minutes per sample)
        #Samtools flagstat has required metrics for this stage
        samtools flagstat {input.bam} > {output.txt}
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
        expand("tmp/{sample}/{sample}_map_umi3_metrics.txt", sample=sample_names)
    output:
        "exp_duplication_metrics/duplication_metrics.txt"
    script:
        "scripts/duplication.py"

rule exp_correctproduct_metrics:
    input:
        demux_json = "metrics/demux_metrics.json",
        trim_reports = expand("metrics/{sample}/{sample}_trimfilter_metrics.json", sample=sample_names),
        flagstats = expand("metrics/{sample}/{sample}_map_metrics.txt", sample=sample_names)
    output:
        "exp_correctproduct_metrics/correctproduct_metrics.txt"
    params:
        samples = sample_names
    script:
        "scripts/correctproduct.py"

rule exp_rawreadcounts_metrics:
    input:
        json = "metrics/demux_metrics.json"
    output:
        readcounts = "metrics/sample_readcounts_metrics.txt"
    params:
        fasta = r1start,
        used = sample_names
    script:
        "scripts/rawreadcounts.py"

rule exp_batchcontamination_metrics:
    input:
        json = "metrics/demux_metrics.json"
    output:
        contamination = "metrics/batchcontamination_metrics.txt"
    params:
        fasta = r1start,
        used = sample_names
    script:
        "scripts/batchcontamination.py"