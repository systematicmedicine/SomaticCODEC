"""
--- ms_call_germ.smk ---

Rules for ...

Input: ...
Output: ...

Author: Ben Barry
Dev Status: not operational

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
        bam= "tmp/data/raw/Sample01_map_ssc_anno_chr1.bam"
    output:
        bam="tmp/data/processed/Sample01_sort.bam"
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
        stats="tmp/data/processed/Sample01_chr1_flagstat.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.stats}
        """

# using Haplotypecaller to call germline varients
# note - here Chr1 is explicitly being called on to speed things up.
rule ms_call_germ_variants:
    input:
        bam=rules.ms_sort_bam.output.bam,
        ref= "tmp/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
    output:
        vcf="tmp/data/processed/Sample01_chr1.vcf.gz"
    shell:
        """
        gatk --java-options "-Xmx8g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            -L chr1

        """
# intial hard filtering params
#note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_variants:
    input:
        vcf= rules.ms_call_germ_variants.output.vcf,
        ref="tmp/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
    output:
        vcf="tmp/data/processed/Sample01_hardFilter.vcf"
    shell:
        """
        gatk VariantFiltration \
        -V {input.vcf} \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "QUAL < 30.0" --filter-name "QUAL30" \
        -filter "SOR > 3.0" --filter-name "SOR3" \
        -filter "FS > 60.0" --filter-name "FS60" \
        -filter "MQ < 40.0" --filter-name "MQ40" \
        -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
        -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
        -O {output.vcf}
        """    

rule ms_filter_pass_variants:
    input:
        vcf =rules.ms_hard_filter_variants
    output:
        vcf = "tmp/data/processed/Sample01_hardFilter_passed.vcf"
    shell:
        """
        gatk SelectVariants
        -V {input.vcf} \
        --exclude-filtered true \
        -O {output.vcf}

        """




#create filter for heterozygous regions which pass the hard filtering
rule: heterozygous_bed:
    input:
        vcf= rules.ms_filter_pass_variants
    output:
        vcf= "tmp/data/processed/Sample01_het_variants.vcf"
        bed= "tmp/data/bed/Sample01_het_variants_bed"
    shell:
        """
        # create a vcf file of het regions only
        bcftools view -f PASS -g het -Ov -o {output.vcf} {input.vcf}

        
        # Convert filtered VCF to BED format
        vcf2bed < {output.vcf} > {output.bed}
        """

