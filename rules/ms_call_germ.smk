"""
--- ms_call_germ.smk ---

Rules for ...

Input: ...
Output: ...

Author: Ben Barry

"""

# Sort the input BAM file, this might not be necescary/previously done. 
rule ms_sort_bam:
    input:
        bam= inputBam
    output:
        bam="data/processed/{Sample}_sort.bam"
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
        bam=rules.SortSAM.output.bam
    output:
        stats="data/processed/{Sample}_chr1_flagstat.txt"
    shell:
        """
        samtools flagstat {input.bam} > {output.stats}
        """

# This needs a comment
rule ms_call_germ_variants:
    input:
        bam=rules.SortSAM.output.bam,
        ref= ref
    output:
        vcf="/home/bdbarry/20250602_reference_pseudogenome/data/processed/{Sample}_{chr}.vcf.gz"
    shell:
        """
        gatk --java-options "-Xmx8g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            -L {chr} \
            
        """
