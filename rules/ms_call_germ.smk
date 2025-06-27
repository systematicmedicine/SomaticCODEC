"""
--- ms_call_germ.smk ---

Rules for calling and filtering germline variants

Input: 
    - Aligned, sorted and dulpicate marked BAM
    - GCRh38 human reference genome
Output: 
    - Filtered VCF file

Author: Ben Barry

"""

# Call candidate germline variants (no filtering)
rule ms_candidate_germ_variants:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_markdup_map.bam",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
        dictf = os.path.splitext(config["GRCh38_path"])[0] + ".dict"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz")
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

# Convert MNVs and complicated subsitutions into SNV and /or INDELs
rule ms_decompose_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_candidate_variants.vcf.gz",
        ref = config["GRCh38_path"],
        fai = config["GRCh38_path"] + ".fai",
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_decomposed_variants.vcf.gz")
    shell:
        """
        bcftools norm -m -both -f {input.ref} {input.vcf} -Oz -o {output.vcf}
        tabix -p vcf {output.vcf}
        """

# Select SNVs from decomposed VCF
rule ms_select_snvs:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_decomposed_variants.vcf.gz",
        ref = config["GRCh38_path"]
    output:
        SNVs = temp("tmp/{ms_sample}/{ms_sample}_ms_selected_snvs.vcf.gz")
    shell:
        """
        gatk SelectVariants \
          -R {input.ref} \
          -V {input.vcf} \
          --select-type-to-include SNP \
          -O {output.SNVs}
        """

# Flags SNVs for filtering
rule ms_flag_snvs:
    input:
        SNVs = "tmp/{ms_sample}/{ms_sample}_ms_selected_snvs.vcf.gz"
    output:
        SNV_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_flagged_snvs.vcf.gz")
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

# Selects indels from decomposed vcf
rule ms_select_indels:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_decomposed_variants.vcf.gz",
        ref = config["GRCh38_path"]
    output:
        INDELs = temp("tmp/{ms_sample}/{ms_sample}_ms_selected_indels.vcf.gz")
    shell:
        """
        gatk SelectVariants \
          -R {input.ref} \
          -V {input.vcf} \
          --select-type-to-include INDEL \
          -O {output.INDELs}
        """

# Flags indels for filtering
rule ms_flag_indels:
    input:
        INDELs = "tmp/{ms_sample}/{ms_sample}_ms_selected_indels.vcf.gz"
    output:
        INDEL_filtered = temp("tmp/{ms_sample}/{ms_sample}_ms_flagged_indels.vcf.gz")
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
rule ms_merge_flagged_vcfs:
    input:
        snv = "tmp/{ms_sample}/{ms_sample}_ms_flagged_snvs.vcf.gz",
        indel = "tmp/{ms_sample}/{ms_sample}_ms_flagged_indels.vcf.gz"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_merged_flagged.vcf.gz")
    shell:
        """
        gatk MergeVcfs \
        -I {input.snv}  \
        -I {input.indel} \
        -O {output.vcf} 
        """
        
# Filter germline variants
rule ms_filter_variants:
    input:
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_merged_flagged.vcf.gz"
    output:
        vcf = temp("tmp/{ms_sample}/{ms_sample}_ms_filtered_variants.vcf.gz")
    shell:
        """
        bcftools view -f PASS -Oz -o {output.vcf} {input.vcf}
        """
