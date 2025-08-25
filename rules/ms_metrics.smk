"""
--- ms_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.

Authors: 
    - Joshua Johnstone
    - Ben Barry
    - Cameron Fraser

"""

import scripts.get_metadata as md

# Generates a fastqc report for demuxed ms FASTQs
rule ms_raw_fastq_metrics:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        variant_chroms_check = "logs/pipeline/check_variant_calling_chroms_present.done",
        ms_samples = config["files"]["ms_samples"],
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
    shell:
        """        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2} 2>> {log}

        unzip -p {output.r1_zip} */fastqc_data.txt > {output.r1_txt} 2>> {log}

        unzip -p {output.r2_zip} */fastqc_data.txt > {output.r2_txt} 2>> {log}
        """


# Generates a summary of key metrics for ms fastqc reports
rule ms_fastqc_summary_metrics:
    input:
        fastqc_files = expand("metrics/{ms_sample}/{ms_sample}_{filetype}_fastqc.txt", 
        filetype = ["r1_raw", "r2_raw", "filter_r1", "filter_r2"],
        ms_sample = md.get_ms_sample_ids(config))
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
    script:
        "../scripts/fastqc_summary_metrics.py"


# Generates ms alignment metrics
rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt",
        insert_metrics = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"
    log:
        "logs/{ms_sample}/ms_alignment_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.stats} 2>> {log}

        picard CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} 2>> {log}
        """ 


# Generates ms duplicate metrics
rule ms_duplication_metrics:
    input:
        bam_sorted = "tmp/{ms_sample}/{ms_sample}_read_group_map.bam"
    output:
        bam_markdup = temp("tmp/{ms_sample}/{ms_sample}_markdup_map.bam"),
        dup_metrics = "metrics/{ms_sample}/{ms_sample}_markdup_metrics.txt"
    log:
        "logs/{ms_sample}/ms_duplication_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_duplication_metrics.benchmark.txt"
    shell:
        """
        picard MarkDuplicates \
        I={input.bam_sorted} \
        O={output.bam_markdup} \
        M={output.dup_metrics} \
        CREATE_INDEX=false 2>> {log}
        """


# Generates metrics for candidate ms germline variants
rule ms_candidate_variant_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_candidate_variant_metrics.txt"
    log:
        "logs/{ms_sample}/ms_candidate_variant_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_candidate_variant_metrics.benchmark.txt"
    shell:
        """
        bcftools stats -s - {input.vcf} > {output.stat} 2>> {log}
        """

# calculate the het/hom ratio from ms vcf
rule ms_het_hom_ratio:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    output:
        ms_het_hom_ratio = "metrics/{ms_sample}/{ms_sample}_ms_het_hom_ratio.txt",
        intermediate_txt = temp("tmp/{ms_sample}/{ms_sample}_ms_genotypes.txt"),
        intermediate_sorted = temp("tmp/{ms_sample}/{ms_sample}_ms_genotypes_sorted.txt"),
        intermediate_counts = temp("tmp/{ms_sample}/{ms_sample}_ms_genotype_counts.txt")
    log:
        "logs/{ms_sample}/ms_het_hom_ratio.log"
    benchmark:
        "logs/{ms_sample}/ms_het_hom_ratio.benchmark.txt"
    shell:
        """
        bcftools query -f '[%GT\\n]' {input.vcf} > {output.intermediate_txt} 2>> {log}
        sort {output.intermediate_txt} > {output.intermediate_sorted} 2>> {log}
        uniq -c {output.intermediate_sorted} > {output.intermediate_counts} 2>> {log}

        awk '
            {{
                if ($2 == "0/1" || $2 == "1/0" || $2 == "1/2") het += $1;
                else if ($2 == "1/1") hom += $1;
            }}
            END {{
                print "Heterozygous_count", "Homozygous_count", "Het/Hom_Ratio";
                het += 0; hom += 0;
                print het, hom, (hom > 0 ? het / hom : "NA");
            }}
        ' OFS="\\t" {output.intermediate_counts} > {output.ms_het_hom_ratio} 2>> {log}
        """


# Generates metrics for each mask BED file
rule ms_masking_metrics:
    input:
        common_masks = expand("{mask}", mask=config["files"]["common_masks"]),
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        combined_bed = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed",
        ref_index = config["files"]["reference"] + ".fai"
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
    script:
       "../scripts/ms_masking_metrics.py"


# Generates a summary of key metrics for candidate ms germline variants
rule ms_candidate_variant_metrics_summary:
    input: 
        variant_metrics = "metrics/{ms_sample}/{ms_sample}_candidate_variant_metrics.txt",
        ms_het_hom_ratio = "metrics/{ms_sample}/{ms_sample}_ms_het_hom_ratio.txt",
        depth_hist = "metrics/{ms_sample}/{ms_sample}_depth_histogram.txt"
    output:
        summary = "metrics/{ms_sample}/{ms_sample}_candidate_variant_metrics_summary.json"
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_candidate_variant_metrics_summary.log"
    benchmark:
        "logs/{ms_sample}/ms_candidate_variant_metrics_summary.benchmark.txt"
    script:
        "../scripts/ms_candidate_variant_metrics_summary.py"

