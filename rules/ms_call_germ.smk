"""
--- ms_call_germ.smk ---

Rules for calling and filtering germline variants

Input: 
    -aligned, sorted and dulpicate marked BAM
    - HG38 human reference genome
Output: 
    - Filtered VCF file
    - Germline Variant metric file

Author: Ben Barry

"""

# Use Haplotypecaller to call germline varients
    # "-Xmx32g" allocates 32GB of RAM - can optimised based on prior file sizes
    # "--native-pair-hmm-threads 48" Parallelises HMM across 48 cores
rule ms_call_germ_variants:
    input:
        bam= "tmp/{ms_sample}/{ms_sample}_markdup.bam",
        ref= config['GRCh38_path']
    output:
        vcf= temp("tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz")
    threads:
         max(1, os.cpu_count() // 8)
    shell:
        """
        gatk --java-options "-Xmx32g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            --native-pair-hmm-threads {threads}

        """

# Output Unfiltered variant call summary metrics
rule ms_variant_call_unfiltered_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_variantCall_unfiltered_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}

        """


# Convert MNPs to SNVs and complicated subsitutions into SNV + INDEL
rule ms_decompose_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz",
        ref = config['GRCh38_path']
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz")
    shell:
        """
        bcftools norm -m -both -f {input.ref} {input.vcf} -Oz -o {output.vcf}
        tabix -p vcf {output.vcf}
        """


# Select SNVs and apply standard hard filters to flag low-confidence SNVs:

    # - QD < 2.0: Low variant confidence relative to depth
    # - QUAL < 30.0: Low overall variant confidence
    # - SOR > 3.0 and FS > 60.0: Evidence of strand bias
    # - MQ < 40.0: Poor average mapping quality
    # - MQRankSum < -12.5: Alt reads have lower mapping quality than ref
    # - ReadPosRankSum < -8.0: Alt alleles biased toward read ends

# Note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_SNV:
    input:
        vcf= "tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz",
        ref= config['GRCh38_path']
    output:
        SNV_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_SNV.vcf.gz")
    shell:
        """
        gatk SelectVariants \
        -R {input.ref} \
        -V {input.vcf} \
        --select-type-to-include SNP \
        -O /dev/stdout \
        | \
        gatk VariantFiltration \
        -V /dev/stdin \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "QUAL < 30.0" --filter-name "QUAL30" \
        -filter "SOR > 3.0" --filter-name "SOR3" \
        -filter "FS > 60.0" --filter-name "FS60" \
        -filter "MQ < 40.0" --filter-name "MQ40" \
        -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
        -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
        -O {output.SNV_filtered}

        """    


# select Indels and apply standard hard filters to flag low-confidence INDELs:

    # - QD < 2.0: Low variant confidence relative to depth
    # - QUAL < 30.0: Low overall variant confidence
    # - FS > 200.0: Strong strand bias (Fisher's exact test)
    # - ReadPosRankSum < -20.0: Alt alleles biased toward read ends

# Note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_INDEL:
    input:
        vcf= "tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz",
        ref= config['GRCh38_path']
    output:
        INDEL_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_INDEL.vcf.gz")
    shell:
        """
        gatk SelectVariants \
        -R {input.ref} \
        -V {input.vcf} \
        --select-type-to-include INDEL \
        -O /dev/stdout \
        | \
        gatk VariantFiltration \
        -V /dev/stdin \
        -filter "QD < 2.0" --filter-name "QD2" \
        -filter "QUAL < 30.0" --filter-name "QUAL30" \
        -filter "FS > 200.0" --filter-name "FS200" \
        -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \
        -O {output.INDEL_filtered}

        """


# Merge filtered vcfs
rule ms_merge_filtered:
    input:
        SNV= "tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_SNV.vcf.gz",
        INDEL= "tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_INDEL.vcf.gz"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_merge_filtered.vcf.gz")
    shell:
        """
        gatk MergeVcfs \
        -I {input.SNV}  \
        -I {input.INDEL} \
        -O {output.vcf} 

        """
        

# Filter PASS variants
    # generate an index file
rule ms_filter_pass_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_merge_filtered.vcf.gz"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz"),
        vcf_index = temp("tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz.tbi")

    shell:
        """
        bcftools view -f PASS -Oz -o {output.vcf} {input.vcf}
        tabix -p vcf {output.vcf}

        """


# Output variant call post filtering summary metrics
rule ms_variant_call_filtered_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_variantCall_filtered_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}

        """