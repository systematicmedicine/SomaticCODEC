"""
--- ms_call_germ.smk ---

Rules for ...

Input: aligned, sorted and dulpicate marked BAM
Output: 
    - Filtered VCF file
    - Germline Variant metric file

Author: Ben Barry

"""

# Use Haplotypecaller to call germline varients
rule ms_call_germ_variants:
    input:
        bam= rules.mark_duplicates.output.bam_markdup,
        ref= ref
    output:
        vcf= temp("tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz")
    shell:
        """
        gatk --java-options "-Xmx32g" HaplotypeCaller  \
            -R {input.ref} \
            -I {input.bam} \
            -O {output.vcf} \
            --native-pair-hmm-threads 4

        """


# Apply standard hard filters to flag low-quality SNVs:

    # - QD < 2.0: Low variant confidence relative to depth
    # - QUAL < 30.0: Low overall variant confidence
    # - SOR > 3.0 and FS > 60.0: Evidence of strand bias
    # - MQ < 40.0: Poor average mapping quality
    # - MQRankSum < -12.5: Alt reads have lower mapping quality than ref
    # - ReadPosRankSum < -8.0: Alt alleles biased toward read ends

# Note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_SNV:
    input:
        vcf= rules.ms_call_germ_variants.output.vcf,
        ref= ref
    output:
        SNV_vcf= temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filter_SNV.vcf.gz"),
        SNV_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_SNV.vcf.gz")
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


# Apply standard hard filters to flag low-quality INDELs:

    # - QD < 2.0: Low variant confidence relative to depth
    # - QUAL < 30.0: Low overall variant confidence
    # - FS > 200.0: Strong strand bias (Fisher's exact test)
    # - ReadPosRankSum < -20.0: Alt alleles biased toward read ends

# Note: these are the most basic parameters - significant review required to tune to best fit for this application
rule ms_hard_filter_INDEL:
    input:
        vcf= rules.ms_call_germ_variants.output.vcf,
        ref= ref
    output:
        INDEL_vcf= temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filter_INDEL.vcf.gz"),
        INDEL_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_INDEL.vcf.gz")
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


# Merge filtered vcfs
rule ms_merge_filtered:
    input:
        SNV= rules.ms_hard_filter_SNV.output.SNV_filtered,
        INDEL= rules.ms_hard_filter_INDEL.output.INDEL_filtered
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
        vcf = rules.ms_merge_filtered.output.vcf
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz"),
        vcf_index = temp("tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz.tbi")

    shell:
        """
        bcftools view -f PASS -Oz -o {output.vcf} {input.vcf}
        tabix -p vcf {output.vcf}

        """


# Output variant call summary metrics
rule ms_variant_call_metrics:
    input: 
        vcf =rules.ms_filter_pass_variants.output.vcf
    output:
        stat = "/metrics/{ms_sample}/{ms_sample}_variantCall_summary.txt"
    shell:
        """
        bcftools stats {input.vcf} > {output.stat}

        """


# Convert VCF file to BED for masking of germline variants
# When using --deletions, the stop value of the BED output is determined by the length difference between ALT and REF alleles. 
    #Use of --insertions or --snvs yields a one-base BED element.
rule ms_germline_variants_bed:
    input:
        vcf= rules.ms_filter_pass_variants.output.vcf
    output:
        del_bed= "tmp/data/bed/{ms_sample}_GL_variants_del.bed",
        in_bed= "tmp/data/bed/{ms_sample}_GL_variants_in.bed",
        snv_bed = "tmp/data/bed/{ms_sample}_GL_variants_snv.bed",
        bed = "tmp/data/bed/{ms_sample}_GL_variants.bed"
    shell:
        """
        # Convert filtered VCF to BED format
        zcat {input.vcf} | vcf2bed --deletions > {output.del_bed}
        zcat {input.vcf} | vcf2bed --insertions > {output.in_bed}
        zcat {input.vcf} | vcf2bed --snvs > {output.snv_bed}

        # Concatenate all into a single BED file, preserving exact regions
        cat {output.del_bed} {output.in_bed} {output.snv_bed} | \
            sort -k1,1 -k2,2n > {output.bed}

        """

