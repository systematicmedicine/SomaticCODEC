"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: Filtered double stranded consensus (.bam)
Output: Somatic mutation calls (.vcf)

Somatic mutations are directly called against the filtered double stranded consensus BAM (single stranded overhangs and read 1 read 2 disagreements removed).
Some areas are masked using bed files (illumina difficlut regions, areas where germline depth is insufficient)

Author: James Phie
"""

# Creates mapping between experimental (codec) and matched sample (standard illumina sequencing) sample names
ex_to_ms = ex_samples.set_index("ex_sample")["ms_sample"].to_dict()

# Use the combined bed for masking germline mutations and difficult regions to create an include regions bed file for variant calling
rule generate_include_bed:
    input:
        mask_bed = lambda wildcards: f"tmp/{ex_to_ms[wildcards.ex_sample]}/{ex_to_ms[wildcards.ex_sample]}_combined_mask.bed",
        fai = config["GRCh38_path"] + ".fai"
    output:
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    shell:
        """
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed}
        """

# Call somatic mutations using the filtered duplex bam
    # Bases with quality of >=Q70 (ie. individual R1 and R2 bases were ~Q35) are filtered (~<200 false positives per diploid genome)
    # Indels are excluded from variant calling (SNVs only)
    # Multiallelic calls (all alt alleles called, e.g. If position X has AGCTTTTTTTTTT, an A mutation, G mutation and C mutation will be called)
rule ex_call_somatic_variants:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        ref = config["GRCh38_path"],
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        vcf_all = "results/{ex_sample}/{ex_sample}_all_positions.vcf",
        vcf_snvs = "results/{ex_sample}/{ex_sample}_variants.vcf"
    shell:
        """
        bcftools mpileup \
            --fasta-ref {input.ref} \
            --output-type u \
            --min-BQ 70 \
            --min-MQ 0 \
            --no-BAQ \
            --annotate AD,DP \
            --regions-file {input.include_bed} \
            {input.bam} \
        | bcftools call \
            --multiallelic-caller \
            --keep-alts \
            --output-type u \
        | tee >(bcftools view \
                    -e 'TYPE="indel" || TYPE="ref"' \
                | bcftools norm -m -both -Ov -o {output.vcf_snvs}) \
        | bcftools view \
              -e 'TYPE="indel"' \
              -Ov -o {output.vcf_all}
        """

rule ex_somatic_variant_rate:
    input:
        vcf_all = "results/{ex_sample}/{ex_sample}_all_positions.vcf"
    output:
        results = "results/{ex_sample}/{ex_sample}_somatic_variant_rate.txt"
    script:
        "../scripts/ex_somatic_variant_rate.py"
