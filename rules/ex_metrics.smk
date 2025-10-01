"""
--- ex_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.
Specific to the ex section of the pipeline.

Authors: 
    - James Phie
    - Cameron Fraser
    - Joshua Johnstone
"""

# Import modules
import helpers.get_metadata as md


"""
FastQC on raw fastq files (before demultiplexing or any processing)
"""
rule ex_fastqcraw_metrics:
    input:
        setup_files = setup_files,
        ex_lanes = config["files"]["ex_lanes_metadata"],
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
        config["resources"]["threads"]["light"]
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/fastqc_summary_metrics.py"


"""
Generates a summary file with demuxed adaptor counts and Gini coefficient for inequality between adaptors
"""
rule ex_demux_counts_and_gini:
    input:
        demux_metrics = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"
    output:
        demux_gini = "metrics/{ex_lane}/{ex_lane}_demux_counts_and_gini.json"
    log:
        "logs/{ex_lane}/ex_demux_metrics_gini.log"
    benchmark:
        "logs/{ex_lane}/ex_demux_metrics_gini.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_demux_counts_and_gini.py"
    

"""
Calculates the count and percentage of bases lost during ex_trim_fastq
"""
rule ex_bases_trimmed:
    input:
        pre_r1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        pre_r2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        post_r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        post_r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_bases_trimmed.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_bases_trimmed.log"
    benchmark:
        "logs/{ex_sample}/ex_bases_trimmed.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_bases_trimmed.py"


"""
Calculates the length of reads post trimming, outputs percentiles and zero-length reads
"""
rule ex_trimmed_read_length_metrics:
    input:
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_trimmed_read_length_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.benchmark.txt" 
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_trimmed_read_length_metrics.py"


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
        config["resources"]["threads"]["light"]
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
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
        memory = config["resources"]["memory"]["light"]
    log:
        "logs/{ex_sample}/ex_insert_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_insert_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
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
        min_mapq = config["rules"]["ex_filter_dsc"]["min_mapq"],
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_dsc_remap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_remap_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
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
        fai = config["files"]["reference_genome"] + ".fai"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json"
    params: 
        quality_threshold = config["rules"]["ex_call_somatic_snv"]["min_base_quality"],
        sample = "{ex_sample}",
        ms_depth_threshold = config["rules"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_dsc_coverage_metrics.py"


"""
Calculate the number of N bases in bases eligible for variant calling (>0x duplex depth, unmasked, QUAL > min_base_quality)
"""
rule ex_percent_eligible_N_bases:
    input:
        pre_dsc_bam = "tmp/{ex_sample}/{ex_sample}_map_correct.bam",
        post_dsc_bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno.bam",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_percent_eligible_N_bases.json"
    params: 
        min_base_quality_pre_dsc = config["rules"]["ex_trim_fastq"]["quality_cutoff"],
        min_base_quality_post_dsc = config["rules"]["ex_call_somatic_snv"]["min_base_quality"],
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_percent_eligible_N_bases.log"
    benchmark:
        "logs/{ex_sample}/ex_percent_eligible_N_bases.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_percent_eligible_N_bases.py"


"""
Calculate trinucleotide contexts for called somatic mutations
    - Compare to reference contexts using cosine similarity
"""
rule ex_trinucleotide_context_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        ref_fasta_path = config["files"]["reference_genome"],
        context_csv_path = config["files"]["reference_tri_contexts"]
    output:
        sample_csv = "metrics/{ex_sample}/{ex_sample}_trinuc_context.csv",
        similarities_csv = "metrics/{ex_sample}/{ex_sample}_trinuc_similarities.csv",
        plot_pdf = "metrics/{ex_sample}/{ex_sample}_trinuc_plots.pdf"
    log:
        "logs/{ex_sample}/ex_trinuc_context.log"
    benchmark:
        "logs/{ex_sample}/ex_trinuc_context.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_trinuc_contexts.py"


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
    resources:
        memory = config["resources"]["memory"]["light"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_softclipping_metrics.py"


"""
Compares variant rate between chromosomes
"""
rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        fai = config["files"]["reference_genome"] + ".fai"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"]
    log:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_chromosomal_variant_rate_metrics.py"


"""
Identify somatic variants present in multiple samples in a batch
"""
rule ex_recurrent_variant_metrics:
    input:
        vcfs = expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = md.get_ex_sample_ids(config))
    output:
        metrics = "metrics/batch/batch_recurrent_variant_metrics.json"
    log:
        "logs/batch/batch_ex_recurrent_variant_metrics.log"
    benchmark:
        "logs/batch/batch_ex_recurrent_variant_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_recurrent_variant_metrics.py"


"""
Determines how many called somatic variants are present in dataset of common germline variants
"""
rule ex_germline_contamination:
    input:
        somatic_vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        germline_vcf = config["files"]["known_germline_variants"],
        germline_tbi = config["files"]["known_germline_variants"] + ".tbi"
    output:
        intermediate_somatic_bgz = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz"),
        intermediate_somatic_tbi = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz.tbi"),
        germline_matches = "metrics/{ex_sample}/{ex_sample}_germline_matches.vcf",
        metrics_file = "metrics/{ex_sample}/{ex_sample}_germline_contamination_metrics.json"
    log:
        "logs/{ex_sample}/ex_germline_contamination.log"
    benchmark:
        "logs/{ex_sample}/ex_germline_contamination.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_germline_contamination.py"


"""
Calculates the distance to nearest SNV, for each SNV
"""
rule ex_snv_distance_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
    output:
        metrics_json = "metrics/{ex_sample}/{ex_sample}_snv_distance.json"
    log:
        "logs/{ex_sample}/ex_snv_distance_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_distance_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_snv_distance_metrics.py"


"""
Positional distribution of called SNVs
"""
rule ex_snv_position_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        index_path = config["files"]["reference_genome"] + ".fai"
    output:
        metrics_json = "metrics/{ex_sample}/{ex_sample}_snv_position_metrics.json",
        metrics_plot = "metrics/{ex_sample}/{ex_sample}_snv_position_plot.pdf"
    log:
        "logs/{ex_sample}/ex_snv_position_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_position_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_snv_position.R"


"""
Obtains the germline contexts for positions where somatic variants were called
"""
rule ex_somatic_variant_germline_contexts:
    input:
        ms_pileup_bcf = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_ms_pileup.bcf"
        ),
        ex_somatic_vcf = "results/{ex_sample}/{ex_sample}_variants.vcf"
    output:
        vcf = "metrics/{ex_sample}/{ex_sample}_somatic_variant_germline_contexts.vcf"
    log:
        "logs/{ex_sample}/ex_somatic_variant_germline_context.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_germline_context.benchmark.txt"
    threads: 
        config["resources"]["threads"]["light"]
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_somatic_variant_germline_contexts.py"

