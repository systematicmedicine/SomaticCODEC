"""
--- ms_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.

Authors: 
    - Joshua Johnstone
    - Cameron Fraser

"""

import helpers.get_metadata as md

# Generates a fastqc report for demuxed ms FASTQs
rule ms_raw_fastq_metrics:
    input:
        setup_files = setup_files,
        ms_samples = config["files"]["ms_samples_metadata"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html",
        r1_zip = temp("metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.zip"),
        r2_zip = temp("metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.zip"),
        r1_txt = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt",
        r2_txt = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt"
    log:
        "logs/{ms_sample}/ms_raw_fastq_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_raw_fastq_metrics.benchmark.txt"
    threads: 
        config["resources"]["threads"]["light"]
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)

        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.html {output.r1_report} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.html {output.r2_report} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.zip {output.r1_zip} 2>> {log}

        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.zip {output.r2_zip} 2>> {log}

        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}

        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """


# Generates a fastqc report for ms processed reads
rule ms_processed_fastq_metrics:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_filter_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_filter_r2.fastq.gz"
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.html",
        r1_zip = temp("metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.zip"),
        r2_zip = temp("metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.zip"),
        r1_txt = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt",
        r2_txt = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt"
    log:
        "logs/{ms_sample}/ms_processed_fastq_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_processed_fastq_metrics.benchmark.txt"
    threads:
        config["resources"]["threads"]["light"]
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2} 2>> {log}

        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}

        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """


# Generates a summary of key metrics for ms fastqc reports
rule ms_fastqc_summary_metrics:
    input:
        fastqc_files = ["metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt" ]
    output:       
        ms_raw_summary_r1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc_summary.json",
        ms_raw_summary_r2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc_summary.json",
        ms_filter_summary_r1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc_summary.json",
        ms_filter_summary_r2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc_summary.json"
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_fastqc_summary_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_fastqc_summary_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/fastqc_summary_metrics.py"


# Generates ms alignment metrics
rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt",
        insert_metrics = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"
    log:
        "logs/{ms_sample}/ms_alignment_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        samtools flagstat {input.bam} > {output.stats} 2>> {log}

        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} 2>> {log}
        """ 


# Generates ms duplication metrics
rule ms_duplication_metrics:
    input:
        dedup_metrics = "metrics/{ms_sample}/{ms_sample}_dedup_metrics.json"
    output:
        duplication_metrics = "metrics/{ms_sample}/{ms_sample}_duplication_metrics_ms.json"
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_duplication_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_duplication_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
       "../scripts/ms_duplication_metrics.py"


# Calulcates the number of bases at each depth level
rule ms_depth_histogram_metrics:
    input:
        intermediate_depth_per_base = "tmp/{ms_sample}/{ms_sample}_depth_per_base.txt",
    output:
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt",
        intermediate_depth_values = temp("tmp/{ms_sample}/{ms_sample}_depth_values.txt"),
        intermediate_depth_values_sorted = temp("tmp/{ms_sample}/{ms_sample}_depth_values_sorted.txt")
    log:
        "logs/{ms_sample}/ms_low_depth_mask.log"
    benchmark:
        "logs/{ms_sample}/ms_low_depth_mask.benchmark.txt"
    params:
        threshold = config["rules"]["ms_low_depth_mask"]["min_depth"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        awk '{{print $3}}' {input.intermediate_depth_per_base} > {output.intermediate_depth_values} 2>> {log}

        sort -n {output.intermediate_depth_values} > {output.intermediate_depth_values_sorted} 2>> {log}

        uniq -c {output.intermediate_depth_values_sorted} > {output.depth_histogram} 2>> {log}
        """


# Generates a summary of genome coverage by depth
rule ms_coverage_by_depth_metrics:
    input:
        depth_histogram = "metrics/{ms_sample}/{ms_sample}_depth_histogram_counts.txt"
    output:
        coverage_by_depth = "metrics/{ms_sample}/{ms_sample}_coverage_by_depth.json"
    params:
        sample = "{ms_sample}",
        min_depth = config["rules"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_coverage_by_depth_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_coverage_by_depth_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
       "../scripts/ms_coverage_by_depth_metrics.py"


# Generates metrics for germline risk variants 
rule ms_germ_risk_variant_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt"
    log:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        bcftools stats -s - {input.vcf} > {output.stat} 2>> {log}
        """

rule ms_germ_risk_variant_metrics_summary:
    input: 
        variant_metrics = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt",
        pileup_vcf = "tmp/{ms_sample}/{ms_sample}_ms_pileup.vcf"
    output:
        summary = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics_summary.json"
    params:
        sample = "{ms_sample}",
        min_depth = config["rules"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics_summary.log"
    benchmark:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics_summary.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ms_germ_risk_variant_metrics_summary.py"


# Generates metrics for each mask BED file
rule ms_masking_metrics:
    input:
        precomputed_masks = expand("{mask}", mask=config["files"]["precomputed_masks"]),
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        combined_bed = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed",
        ref_index = config["files"]["reference_genome"] + ".fai"
    output:
        mask_metrics = "metrics/{ms_sample}/{ms_sample}_mask_metrics.json",
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_masks_sorted.txt"),
        intermediate_merged = temp("tmp/{ms_sample}/{ms_sample}_masks_merged.txt")
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_masking_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_masking_metrics.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
       "../scripts/ms_masking_metrics.py"