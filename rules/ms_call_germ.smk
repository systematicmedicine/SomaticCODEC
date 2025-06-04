"""
--- ms_call_germ.smk ---

Rules for ...

Input: ...
Output: ...

Author: Ben Barry

"""

# this rule is purely for dev purposes to make the pipeline fast locally
rule slice_bam_region:
    input:
        bam="tmp/data/raw/Sample01_map_ssc_anno_chr1.bam"
    output:
        bam="tmp/data/processed/Sample01_map_ssc_anno_chr1_filter.bam",
        bai="tmp/data/processed/Sample01_map_ssc_anno_chr1_filter.bam.bai"
    shell:
        """
        # Index the input BAM (in-place)
        samtools index {input.bam}

        # Filter region from indexed BAM
        samtools view -b {input.bam} chr1:1000000-1500000 > {output.bam}

        # Index the output BAM
        samtools index {output.bam}
        """

#in a main application the pipeline would start here.
# Sort the input BAM file, this might not be necescary/previously done. 
rule ms_sort_bam:
    input:
        bam= "tmp/data/processed/Sample01_map_ssc_anno_chr1_filter.bam"
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

# This needs a comment
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
            -L chr1 \
            
        """
#rule all:
#    input:
 #       "tmp/data/processed/Sample01_sort.bam",
  #      "tmp/data/processed/Sample01_chr1_flagstat.txt",
   #     "tmp/data/processed/Sample01_chr1.vcf.gz"