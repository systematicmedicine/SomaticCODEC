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
        zip_r1 = temp("metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.zip"),
        zip_r2 = temp("metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.zip"),
        txt_r1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt",
        txt_r2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt"
    log:
        "logs/{ex_lane}/ex_fastqcraw_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqcraw_metrics.benchmark.txt"
    threads: 
        config["resource_allocation"]["threads"]["light"]
    shell:
        """
        fastqc -t {threads} {input.fastq1} -o metrics/ 2>> {log}

        fastqc -t {threads} {input.fastq2} -o metrics/ 2>> {log}

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}

        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}

        mv metrics/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}

        mv metrics/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}

        unzip -p {output.zip_r1} */fastqc_data.txt > {output.txt_r1} 2>> {log}

        unzip -p {output.zip_r2} */fastqc_data.txt > {output.txt_r2} 2>> {log}
        """


"""
Generates a summary of key metrics for ex raw fastqc reports
"""
rule ex_fastqc_raw_summary_metrics:
    input:
        fastqc_files = ["metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt",
        "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt"]
    output:
        ex_lane_raw_summary_r1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json",
        ex_lane_raw_summary_r2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json"
    params:
        sample = "{ex_lane}"
    log:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.benchmark.txt"
    script:
        "../scripts/fastqc_summary_metrics.py"


"""
Generates a summary file with the Gini coefficient of demuxed sample read counts
"""
rule ex_demux_metrics_gini:
    input:
        demux_metrics = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"
    output:
        demux_gini = "metrics/{ex_lane}/{ex_lane}_demux_metrics_gini.json"
    params:
        sample = "{ex_lane}"
    log:
        "logs/{ex_lane}/ex_demux_metrics_gini.log"
    benchmark:
        "logs/{ex_lane}/ex_demux_metrics_gini.benchmark.txt"
    script:
        "../scripts/ex_demux_metrics_gini.py"
    

"""
Calculates the percentage of bases lost during ex_trim_fastq
"""
rule ex_bases_trimmed:
    input:
        counts_json = "metrics/{ex_sample}/{ex_sample}_read_base_counts.json",
        pre_files = ["tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz", "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz"],
        post_files = ["tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz", "tmp/{ex_sample}/{ex_sample}_r2_trim.fastq.gz"]
    output:
        json = "metrics/{ex_sample}/{ex_sample}_bases_trimmed.json"
    log:
        "logs/{ex_sample}/ex_bases_trimmed.log"
    benchmark:
        "logs/{ex_sample}/ex_bases_trimmed.benchmark.txt"
    script:
        "../scripts/percent_reads_bases_lost.py"


"""
FastQC on demultiplexed, trimmed, filtered FASTQs 
"""
rule ex_fastqcfilter_metrics:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz"
    output:
        fastqc_report1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.html",
        fastqc_report2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.html",
        zip_r1 = temp("metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.zip"),
        zip_r2 = temp("metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.zip"),
        txt_r1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt",
        txt_r2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt"
    log:
        "logs/{ex_sample}/ex_fastqctrim_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqctrim_metrics.benchmark.txt"
    threads: 
        config["resource_allocation"]["threads"]["light"]
    shell:
        """
        fastqc -t {threads} {input.fastq1} -o metrics/{wildcards.ex_sample} 2>> {log}

        fastqc -t {threads} {input.fastq2} -o metrics/{wildcards.ex_sample} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.html {output.fastqc_report1} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.html {output.fastqc_report2} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq1} .fastq.gz)_fastqc.zip {output.zip_r1} 2>> {log}

        mv metrics/{wildcards.ex_sample}/$(basename {input.fastq2} .fastq.gz)_fastqc.zip {output.zip_r2} 2>> {log}

        unzip -p {output.zip_r1} */fastqc_data.txt > {output.txt_r1} 2>> {log}
        
        unzip -p {output.zip_r2} */fastqc_data.txt > {output.txt_r2} 2>> {log}
        """


"""
Generates a summary of key metrics for ex filter fastqc reports
"""
rule ex_fastqc_filter_summary_metrics:
    input:
        fastqc_files = ["metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt",
        "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt"]
    output:
        ex_filter_summary_r1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics_summary.json",
        ex_filter_summary_r2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics_summary.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.benchmark.txt"
    script:
        "../scripts/fastqc_summary_metrics.py"


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
Shows distribution of insert sizes (distance between 5' end of R1 and 3' end of R2) for correctly paired (same chr, within 500bp) reads 
"""
rule ex_insert_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
    output:
        txt = "metrics/{ex_sample}/{ex_sample}_insert_metrics.txt",
        hist = "metrics/{ex_sample}/{ex_sample}_insert_metrics.pdf", 
    resources:
        memory = config["resource_allocation"]["memory"]["light"]
    log:
        "logs/{ex_sample}/ex_insert_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_insert_metrics.benchmark.txt"
    shell:
        """
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp \
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
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"
    params:
        sample = "{ex_sample}"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_duplication_metrics.json"
    log:
        "logs/{ex_sample}/ex_duplication_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplication_metrics.benchmark.txt"
    script:
        "../scripts/ex_duplication_metrics.py"


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
Calculate percentage of reads lost when calling DSC
"""
rule ex_call_dsc_metrics:
    input:
        pre_call_bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam",
        post_call_bam = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam"
    output:
        call_dsc_metrics = "metrics/{ex_sample}/{ex_sample}_call_dsc_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_call_dsc_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_call_dsc_metrics.benchmark.txt"
    script:
        "../scripts/ex_call_dsc_metrics.py"

"""
Calculate DSC remapping metrics
    - ex_duplex_realignment: Percentage of reads which successfully aligned during DSC realignment
    - ex_duplex_mapQ: Percentage of reads with a mapQ score of at least 60
"""
rule ex_dsc_remap_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_unsorted.bam",
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_remap_metrics.json"
    params:
        min_mapq = config["ex_filter_dsc"]["min_mapq"],
        sample = "{ex_sample}"
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
        bam_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed",
        ms_depth = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_depth_per_base.txt"
        ),
        fai = config["reference_path"] + ".fai"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json"
    params: 
        quality_threshold = config["ex_call_somatic_snv"]["min_base_quality"],
        sample = "{ex_sample}",
        ms_depth_threshold = config["ms_low_depth_mask"]["threshold"]
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
        vcf_snvs = "results/{ex_sample}/{ex_sample}_variants.vcf",
        nanoseq_contexts = config["ex_nanoseq_tri_contexts"],
        ref = config["reference_path"]
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_trinucleotide_context_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trinucleotide_context_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trinucleotide_context_metrics.benchmark.txt"
    script:
        "../scripts/ex_trinucleotide_context_metrics.py"


"""
Calculate the total read loss between raw FASTQ, and DSC immediately before variant calling
"""
rule ex_total_read_loss:
    input:
        input_fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        input_fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        file_path = "metrics/{ex_sample}/{ex_sample}_total_read_loss.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_total_read_loss.log"
    benchmark:
        "logs/{ex_sample}/ex_total_read_loss.benchmark.txt"
    script:
        "../scripts/ex_total_read_loss.py"


"""
Quantifies how much soft clipping is present in final DSC
"""
rule ex_softclipping_metrics:
    input:
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        file_path = "metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json"
    log:
        "logs/{ex_sample}/ex_softclipping_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_softclipping_metrics.benchmark.txt"
    script:
        "../scripts/ex_softclipping_metrics.py"


rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        fai = config["reference_path"] + ".fai"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"
    log:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"
    script:
        "../scripts/ex_chromosomal_variant_rate_metrics.py"

rule ex_recurrent_variant_metrics:
    input:
        vcfs = expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = md.get_ex_sample_ids(config))
    output:
        metrics = "metrics/batch/batch_recurrent_variant_metrics.json"
    log:
        "logs/batch/batch_ex_recurrent_variant_metrics.log"
    benchmark:
        "logs/batch/batch_ex_recurrent_variant_metrics.benchmark.txt"
    script:
        "../scripts/ex_recurrent_variant_metrics.py"