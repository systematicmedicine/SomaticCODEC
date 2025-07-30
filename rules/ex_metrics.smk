"""
--- ex_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.
Specific to the ex section of the pipeline.

Authors: 
    - James Phie
    - Cameron Fraser
"""

# Import modules
import scripts.get_metadata as md


"""
FastQC on raw fastq files (before demultiplexing or any processing)
"""
rule ex_fastqcraw_metrics:
    input:
        ex_lanes = config["ex_lanes_path"],
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1],
    output:
        fastqc_report1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.html",
        fastqc_report2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.html",
        zip_r1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.zip",
        zip_r2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.zip"
    log:
        "logs/{ex_lane}/ex_fastqcraw_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqcraw_metrics.benchmark.txt"
    threads: 
        4
    shell:
        """
        fastqc -t {threads} {input.fastq1} -o metrics/ 2>> {log}

        fastqc -t {threads} {input.fastq2} -o metrics/ 2>> {log}

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}

        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}

        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}
        """


"""
FastQC on demultiplexed, trimmed, filtered FASTQs 
"""
rule ex_fastqctrim_metrics:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.html",
        zip_r1 = "metrics/{ex_sample}/{ex_sample}_r1_filter_metrics.zip",
        zip_r2 = "metrics/{ex_sample}/{ex_sample}_r2_filter_metrics.zip"
    log:
        "logs/{ex_sample}/ex_fastqctrim_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqctrim_metrics.benchmark.txt"
    threads: 
        4
    shell:
        """
        fastqc -t {threads} {input.fastq1} -o metrics/{wildcards.ex_sample} 2>> {log}

        fastqc -t {threads} {input.fastq2} -o metrics/{wildcards.ex_sample} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}
        """


"""
Collects alignment metrics from the experimental bam mapped to the reference genome
"""
rule ex_map_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map.bam"
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_map_metrics.txt"
    log:
        "logs/{ex_sample}/ex_map_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_map_metrics.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.txt} 2>> {log}
        """


"""
Replace default index names with experiment specific sample names as defined in the input.tsv
"""
rule ex_correctproduct_metrics:
    input:
        ex_samples = config["ex_samples_path"],
        ex_lanes = config["ex_lanes_path"],        
        demux_json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json",
        filter_length = lambda wildcards: expand(
            "metrics/{ex_sample}/{ex_sample}_filter_readlength_metrics.json",
            ex_sample = md.get_ex_lane_samples(config)[wildcards.ex_lane]
        ),
        filter_meanquality = lambda wildcards: expand(
            "metrics/{ex_sample}/{ex_sample}_filter_meanquality_metrics.json",
            ex_sample = md.get_ex_lane_samples(config)[wildcards.ex_lane]
        ),
        flagstats = lambda wildcards: expand(
            "metrics/{ex_sample}/{ex_sample}_map_metrics.txt",
            ex_sample = md.get_ex_lane_samples(config)[wildcards.ex_lane]
        ),
    output:
        file_path = "metrics/{ex_lane}/{ex_lane}_correctproduct_metrics.txt"
    log:
        "logs/{ex_lane}/ex_correctproduct_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_correctproduct_metrics.benchmark.txt"
    script:
        "../scripts/ex_correct_product_metrics.py"


"""
Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
"""
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf", 
    resources:
        mem = 128
    log:
        "logs/{ex_sample}/ex_insert_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_insert_metrics.benchmark.txt"
    shell:
        """
        picard -Xmx{resources.mem}g -Djava.io.tmpdir=tmp \
            CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.txt} \
            H={output.hist} \
            M=0.5 \
            W=600 \
            DEVIATIONS=100 2>> {log}
        """


"""
Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
"""
rule ex_duplication_metrics:
    input:
        ex_samples = config["ex_samples_path"],
        umi_metrics = expand("metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt", ex_sample = md.get_ex_sample_ids(config))
    output:
        file_path = "metrics/ex_duplication_metrics.txt"
    log:
        "logs/ex_duplication_metrics.log"
    benchmark:
        "logs/ex_duplication_metrics.benchmark.txt"
    script:
        "../scripts/ex_duplication_metrics.py"


"""
Custom python script to assess demultiplexing
"""
rule ex_raw_read_counts_metrics:
    input:
        ex_samples = config["ex_samples_path"],
        ex_lanes = config["ex_lanes_path"],
        json = "metrics/{ex_lane}/{ex_lane}_demux_metrics.json"
    output:
        readcounts = "metrics/{ex_lane}/{ex_lane}_sample_readcounts_metrics.txt"
    params:
        fasta = lambda wildcards: f"tmp/{wildcards.ex_lane}/{wildcards.ex_lane}_r1_start.fasta"
    log:
        "logs/{ex_lane}/ex_raw_read_counts_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_raw_read_counts_metrics.benchmark.txt"
    script:
        "../scripts/ex_raw_read_counts_metrics.py"


"""
Calculate the somatic variant rate
"""
rule ex_somatic_variant_rate:
    input:
        vcf_all = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf"
    output:
        results = "metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.txt"
    log:
        "logs/{ex_sample}/ex_somatic_variant_rate.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_rate.benchmark.txt"
    script:
        "../scripts/ex_somatic_variant_rate.py"


"""
Calculate DSC remapping metrics
    - ex_duplex_realignment: Percentage of reads which successfully aligned during DSC realignment
    - ex_duplex_mapQ: Percentage of reads with a mapQ score of at least 60
"""
rule ex_dsc_remap_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam",
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_remap_metrics.txt"
    log:
        "logs/{ex_sample}/ex_dsc_remap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_remap_metrics.benchmark.txt"
    script:
        "../scripts/ex_dsc_remap_metrics.py"


"""
Calculate DSC coverage metrics
    - ex_mean_analyzable_duplex_depth: Total duplex bases in include_beg region divided by total positions in include_bed region
    - ex_duplex_coverage_bedregions: Percentage of positions in include_bed region that have >0x duplex depth
    - ex_duplex_coverage_wholegenome: Positions with >0x duplex depth in the include_bed region as a percentage of the whole genome
"""
rule ex_dsc_coverage_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.txt"
    log:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.benchmark.txt"
    script:
        "../scripts/ex_dsc_coverage_metrics.py"

"""
Calculate percent of positions with somatic SNV clustering
    - ex_somatic_depth_per_position: Percent of somatic SNVs called that have >1x alt depth
    - ex_somatic_clustered_or_mnv: Percent of somatic SNVs called that are within 150bp of another SNV
"""
rule ex_somatic_SNV_clustering_metrics:
    input:
        vcf_snvs = "results/{ex_sample}/{ex_sample}_variants.vcf"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_somatic_clustering_metrics.txt"
    log:
        "logs/{ex_sample}/ex_somatic_SNV_clustering_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_SNV_clustering_metrics.benchmark.txt"
    script:
        "../scripts/ex_somatic_SNV_clustering_metrics.py"

"""
Calculate 96 trinucleotide contexts for called somatic mutations
    - ex_trinucleotide_cosine_similarity: Cosine similarity compared to nanoseq granulocyte data (which also matches closely with Bae 2023 trinucleotide contexts)
"""
rule ex_trinucleotide_context_metrics:
    input:
        vcf_snvs = expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = md.get_ex_sample_ids(config)),
        nanoseq_contexts = config["ex_nanoseq_tri_contexts"],
        ref = config["GRCh38_path"]
    output:
        metrics = "metrics/trinucleotide_context_metrics.txt"
    log:
        "logs/ex_trinucleotide_context_metrics.log"
    benchmark:
        "logs/ex_trinucleotide_context_metrics.benchmark.txt"
    script:
        "../scripts/ex_trinucleotide_context_metrics.py"


"""
Calculate the total read loss between raw FASTQ, and DSC immediately before variant calling
"""
rule ex_total_read_loss:
    input:
        ex_samples = config["ex_samples_path"],
        ex_lanes = config["ex_lanes_path"],
        input_fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        input_fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1],
        dsc_final = lambda wildcards: expand(
            "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
            ex_sample = md.get_ex_lane_samples(config)[wildcards.ex_lane]
        ),
    output:
        file_path = "metrics/{ex_lane}/{ex_lane}_total_read_loss.json"
    log:
        "logs/{ex_lane}/ex_total_read_loss.log"
    benchmark:
        "logs/{ex_lane}/{ex_lane}_ex_total_read_loss.benchmark.txt"
    script:
        "../scripts/ex_total_read_loss.py"