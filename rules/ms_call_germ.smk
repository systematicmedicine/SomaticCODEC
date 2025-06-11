"""
--- ms_call_germ.smk ---

Rules for ...

Input: ...
Output: ...

Author: Ben Barry

"""

#this rule is purely for dev purposes to make the pipeline fast locally

#rule slice_bam_region:
#    input:
#        bam="tmp/data/raw/Sample01_map_ssc_anno_chr1.bam"
#    output:
#        bam="tmp/data/processed/Sample01_map_ssc_anno_chr1_filter.bam",
#        bai="tmp/data/processed/Sample01_map_ssc_anno_chr1_filter.bam.bai"
#    shell:
#        """
#        # Index the input BAM (in-place)
#        samtools index {input.bam}
#
#        # Filter region from indexed BAM
#        samtools view -b {input.bam} chr1:1000000-1500000 > {output.bam}
#
#        # Index the output BAM
#        samtools index {output.bam}
#        """

#in a main application the pipeline would start here.
# Sort the input BAM file, this might not be necescary/previously done. 
rule ms_sort_bam:
    input:
        bam= input_bam
    output:
        bam= temp("tmp/data/processed/{sample}_sort.bam")
    shell:
        """
        picard -Xmx7g SortSam \
            INPUT={input.bam} \
            OUTPUT={output.bam} \
            SORT_ORDER=coordinate \
            VALIDATION_STRINGENCY=LENIENT \
            CREATE_INDEX=True \
            MAX_RECORDS_IN_RAM=3000000
        """

# create a summary statistic which can be viewed for QC - again may not be necescecary 
rule ms_alignment_metrics:
    input:
        bam=rules.ms_sort_bam.output.bam
    output:
        stats="tmp/data/processed/{sample}_chr1_flagstat.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.stats}
        """

# using Haplotypecaller to call germline varients
# note - here Chr1 is explicitly being called on to speed things up.
rule ms_call_germ_variants:
    input:
        bam=rules.ms_sort_bam.output.bam,
        ref= HG38
    output:
        vcf="tmp/data/processed/{sample}_chr1.vcf.gz"
    shell:
        """
        gatk --java-options "-Xmx8g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            -L chr1

        """


# select and filter SNV calls
#note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_SNV:
    input:
        vcf= rules.ms_call_germ_variants.output.vcf,
        ref= HG38
    output:
        SNV_vcf= temp("tmp/data/processed/{sample}_SNV.vcf.gz"),
        SNV_filtered = "tmp/data/processed/{sample}_SNV_filtered.vcf.gz"
    shell:
        """
        gatk SelectVariants \
        -R {input.ref} \
        -V {input.vcf} \
        --select-type-to-include SNP \
        -O {output.SNV_vcf}


        gatk VariantFiltration \
        -V {output.SNV_vcf} \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "QUAL < 30.0" --filter-name "QUAL30" \
        -filter "SOR > 3.0" --filter-name "SOR3" \
        -filter "FS > 60.0" --filter-name "FS60" \
        -filter "MQ < 40.0" --filter-name "MQ40" \
        -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
        -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
        -O {output.SNV_filtered}

        """    

#select and filter indel calls
rule ms_hard_filter_INDEL:
    input:
        vcf= rules.ms_call_germ_variants.output.vcf,
        ref= HG38
    output:
        INDEL_vcf= temp("tmp/data/processed/{sample}_INDEL.vcf.gz"),
        INDEL_filtered = "tmp/data/processed/{sample}_INDEL_filtered.vcf.gz"
    shell:
        """
        gatk SelectVariants \
        -R {input.ref} \
        -V {input.vcf} \
        --select-type-to-include INDEL \
        -O {output.INDEL_vcf}


        gatk VariantFiltration \
        -V {output.INDEL_vcf} \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "QUAL < 30.0" --filter-name "QUAL30" \
        -filter "FS > 200.0" --filter-name "FS200" \
        -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \
        -O {output.INDEL_filtered}

        """

#merge filtered vcfs
rule ms_merge_filtered:
    input:
        SNV= rules.ms_hard_filter_SNV.output.SNV_filtered,
        INDEL= rules.ms_hard_filter_INDEL.output.INDEL_filtered
    output:
        vcf = "tmp/data/processed/{sample}_hardfilter.vcf.gz"
    shell:
        """
        gatk MergeVcfs \
        -I {input.SNV}  \
        -I {input.INDEL} \
        -O {output.vcf} 

        """
#select only the variants which pass
rule ms_filter_pass_variants:
    input:
        vcf = rules.ms_merge_filtered.output.vcf
    output:
        vcf = "tmp/data/processed/{sample}_hardFilter_passed.vcf.gz"
    shell:
        """
        # select only variants which pass filter metrics
        gatk SelectVariants \
        -V {input.vcf} \
        --exclude-filtered true \
        -O {output.vcf}

        """

#output variant call summary metrics
rule ms_variant_call_metrics:
    input: 
        vcf =rules.ms_filter_pass_variants.output.vcf
    output:
        stat = "tmp/metrics/{sample}_variantCall_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}

        """



#create filter for heterozygous regions which pass the hard filtering
rule ms_heterozygous_bed:
    input:
        vcf= rules.ms_filter_pass_variants.output.vcf
    output:
        vcf= "tmp/data/processed/{sample}_het_variants.vcf",
        bed= "tmp/data/bed/{sample}_het_variants.bed"
    shell:
        """
        # create a vcf file of het regions only
        bcftools view -f PASS -g het -Ov -o {output.vcf} {input.vcf}

        # Convert filtered VCF to BED format
        vcf2bed < {output.vcf} > {output.bed}

        """

