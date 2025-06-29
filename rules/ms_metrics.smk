"""
--- ms_metrics.smk ---

Rules for creating metrics files that are not created during data processing steps.

Authors: 
    - Joshua Johnstone
    - Ben Barry

"""

# Generates a fastqc report for demuxed ms FASTQs
rule ms_raw_fastq_metrics:
    input:
        r1 = lambda wc: ms_samples.query(f"ms_sample == '{wc.ms_sample}'")["fastq1"].values[0],
        r2 = lambda wc: ms_samples.query(f"ms_sample == '{wc.ms_sample}'")["fastq2"].values[0]
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.html"
    threads: 
        max(1, os.cpu_count() // 16)
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)
        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.html {output.r2_report}
        """

# Generates a fastqc report for ms processed reads
rule ms_processed_fastq_metrics:
    input:
        r1 = "tmp/{ms_sample}/{ms_sample}_trimfilter_r1.fastq.gz",
        r2 = "tmp/{ms_sample}/{ms_sample}_trimfilter_r2.fastq.gz"
    output:
        r1_report = "metrics/{ms_sample}/{ms_sample}_trimfilter_r1_fastqc.html",
        r2_report = "metrics/{ms_sample}/{ms_sample}_trimfilter_r2_fastqc.html"
    threads:
        max(1, os.cpu_count() // 16)
    shell:
        """
        r1_base=$(basename {input.r1} .fastq.gz)
        r2_base=$(basename {input.r2} .fastq.gz)
        
        fastqc -t {threads} -o metrics/{wildcards.ms_sample} {input.r1} {input.r2}

        mv metrics/{wildcards.ms_sample}/${{r1_base}}_fastqc.html {output.r1_report}
        mv metrics/{wildcards.ms_sample}/${{r2_base}}_fastqc.html {output.r2_report}
        """

# Generates ms alignment metrics
rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_markdup_map.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt",
        insert_metrics = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"
    shell:
        """
        # Generate alignment stats
        samtools stats {input.bam} > {output.stats}

        # Collect insert size metrics
        picard CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist}  
        """ 

# Generates metrics for candidate (unfiltered) ms germline variants
rule ms_candidate_variant_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_variantCall_unfiltered_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}
        """

# Generates metrics for filtered ms germline variants
rule ms_filtered_variant_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filtered_variants.vcf.gz"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_variantCall_filtered_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}
        """

# Generates metrics for each mask BED file
rule masking_metrics:
    input:
        gnomAD_bed = config['common_variants_path'],
        GIAB_bed = config['difficult_regions_path'],
        ms_lowdepth_bed = "tmp/{ms_sample}/{ms_sample}_lowdepth.bed",
        ms_germ_del_bed = "tmp/{ms_sample}/{ms_sample}_germ_deletions.bed",
        ms_germ_ins_bed = "tmp/{ms_sample}/{ms_sample}_germ_insertions.bed",
        ms_germ_snv_bed = "tmp/{ms_sample}/{ms_sample}_germ_snvs.bed",
        combined_bed = "tmp/{ms_sample}/{ms_sample}_combined_mask.bed",
        ref_index = config['GRCh38_path'] + ".fai"
    output:
        mask_metrics = "metrics/{ms_sample}/{ms_sample}_mask_metrics.txt"
    shell:
        """
        total_genome_bp=$(awk '{{sum += $2}} END {{print sum}}' {input.ref_index})

        printf "Mask File\\tMasked bases\\t%% of ref genome\\n" > {output.mask_metrics}

        for bed in \\
            {input.gnomAD_bed} \\
            {input.GIAB_bed} \\
            {input.ms_lowdepth_bed} \\
            {input.ms_germ_del_bed} \\
            {input.ms_germ_ins_bed} \\
            {input.ms_germ_snv_bed} \\
            {input.combined_bed}
        do
            name=$(basename "$bed")
            masked_bp=$(bedtools sort -i "$bed" | bedtools merge -i - | awk '{{sum += $3 - $2}} END {{print sum}}')
            pct=$(awk -v masked="$masked_bp" -v total="$total_genome_bp" 'BEGIN {{printf "%.2f", (masked / total) * 100}}')
            printf "%s\\t%s\\t%s%%\\n" "$name" "$masked_bp" "$pct" >> {output.mask_metrics}
        done
        """

# calculate the het/hom ratio from ms vcf
rule ms_het_hom_ratio:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filtered_variants.vcf.gz"
    output:
        ms_het_hom_ratio = "metrics/{ms_sample}/{ms_sample}_ms_het_hom_ratio.txt"
    shell: 
        """
        bcftools query -f '[%GT\\n]' {input.vcf} \\
            | sort | uniq -c \\
            | awk '
                {{
                    if ($2 == "0/1" || $2 == "1/0" || $2 == "1/2") het += $1;
                    else if ($2 == "1/1") hom += $1;
                }}
                END {{
                    print "Heterozygous_count", "Homozygous_count", "Het/Hom_Ratio";
                    het += 0; hom += 0;
                    print het, hom, (hom > 0 ? het / hom : "NA");
                }}
            ' OFS="\\t" > {output.ms_het_hom_ratio}
        """
