"""
--- ms_call_germ.smk ---

Rules for calling and filtering germline variants

Input: 
    - Aligned, sorted and dulpicate marked BAM
    - HG38 human reference genome
Output: 
    - Filtered VCF file
    - Germline Variant metric file

Author: Ben Barry

"""

# Use Haplotypecaller to call germline variants (no filtering)
rule ms_call_germ_variants:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_markdup.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = os.path.splitext(config["GRCh38_path"])[0] + ".dict"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz")
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

# Convert MNVs to SNVs and complicated subsitutions into SNV + INDEL
rule ms_decompose_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_call_germ_variants.vcf.gz",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz")
    shell:
        """
        bcftools norm -m -both -f {input.ref} {input.vcf} -Oz -o {output.vcf}
        tabix -p vcf {output.vcf}
        """

# Select SNVs from decomposed vcf
rule ms_select_SNV:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz",
        ref = config["GRCh38_path"]
    output:
        SNVs = temp("tmp/{ms_sample}/{ms_sample}_ms_SNVs.vcf.gz")
    shell:
        """
        gatk SelectVariants \
          -R {input.ref} \
          -V {input.vcf} \
          --select-type-to-include SNP \
          -O {output.SNVs}
        """
# Flags SNVs for filtering
rule ms_hard_filter_SNV:
    input:
        SNVs = "tmp/{ms_sample}/{ms_sample}_ms_SNVs.vcf.gz"
    output:
        SNV_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_SNV.vcf.gz")
    shell:
        """
        gatk VariantFiltration \
          -V {input.SNVs} \
          -filter "QD < 2.0" --filter-name "QD2" \
          -filter "QUAL < 30.0" --filter-name "QUAL30" \
          -filter "SOR > 3.0" --filter-name "SOR3" \
          -filter "FS > 60.0" --filter-name "FS60" \
          -filter "MQ < 40.0" --filter-name "MQ40" \
          -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \
          -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \
          -O {output.SNV_filtered}
        """
# Selects INDELs from decomposed vcf
rule ms_select_INDEL:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_decomposed.vcf.gz",
        ref = config["GRCh38_path"]
    output:
        INDELs = temp("tmp/{ms_sample}/{ms_sample}_ms_INDELs.vcf.gz")
    shell:
        """
        gatk SelectVariants \
          -R {input.ref} \
          -V {input.vcf} \
          --select-type-to-include INDEL \
          -O {output.INDELs}
        """
# Flags INDELs for filtering
rule ms_hard_filter_INDEL:
    input:
        INDELs = "tmp/{ms_sample}/{ms_sample}_ms_INDELs.vcf.gz"
    output:
        INDEL_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_INDEL.vcf.gz")
    shell:
        """
        gatk VariantFiltration \
          -V {input.INDELs} \
          -filter "QD < 2.0" --filter-name "QD2" \
          -filter "QUAL < 30.0" --filter-name "QUAL30" \
          -filter "FS > 200.0" --filter-name "FS200" \
          -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \
          -O {output.INDEL_filtered}
        """

# Merge flagged vcfs (SVNs and indels)
rule ms_merge_filtered:
    input:
        SNV = "tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_SNV.vcf.gz",
        INDEL = "tmp/{ms_sample}/{ms_sample}_ms_hard_filtered_INDEL.vcf.gz"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_merge_filtered.vcf.gz")
    shell:
        """
        gatk MergeVcfs \
        -I {input.SNV}  \
        -I {input.INDEL} \
        -O {output.vcf} 
        """
        
# Filter germline variants (based on flagging in previous rules)
rule ms_filter_pass_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_merge_filtered.vcf.gz"
    output:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz", #Make temp once development is complete
        vcf_index = "tmp/{ms_sample}/{ms_sample}_ms_filter_pass_variants.vcf.gz.tbi" #Make temp once development is complete

    shell:
        """
        bcftools view -f PASS -Oz -o {output.vcf} {input.vcf}
        tabix -p vcf {output.vcf}
        """
