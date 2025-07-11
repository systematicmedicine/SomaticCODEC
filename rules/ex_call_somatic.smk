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
    log:
        "logs/{ex_sample}/generate_include_bed.log"
    benchmark:
        "logs/{ex_sample}/generate_include_bed.benchmark.txt"
    shell:
        """
        bedtools complement -i {input.mask_bed} -g {input.fai} > {output.include_bed} 2>> {log}
        """

rule ex_call_somatic_variants:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        ref = config["GRCh38_path"],
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        vcf_all = "results/{ex_sample}/{ex_sample}_all_positions.vcf",
        vcf_snvs = "results/{ex_sample}/{ex_sample}_variants.vcf",
        intermediate_mpileup = temp("tmp/{ex_sample}/{ex_sample}_bcf_mpileup.bcf"),
        intermediate_called = temp("tmp/{ex_sample}/{ex_sample}_bcf_called.bcf"),
        intermediate_biallelic = temp("tmp/{ex_sample}/{ex_sample}_bcf_biallelic.bcf")
    log:
        "logs/{ex_sample}/ex_call_somatic_variants.log"
    benchmark:
        "logs/{ex_sample}/ex_call_somatic_variants.benchmark.txt"
    shell:
        """
        bcftools mpileup \
            --fasta-ref {input.ref} \
            --output-type b \
            --count-orphans \
            --max-BQ 150 \
            --min-BQ 70 \
            --min-MQ 0 \
            --no-BAQ \
            --annotate AD,DP \
            --regions-file {input.include_bed} \
            {input.bam} \
            -o {output.intermediate_mpileup} 2>> {log}

        bcftools call \
            --multiallelic-caller \
            --keep-alts \
            --output-type b \
            -o {output.intermediate_called} \
            {output.intermediate_mpileup} 2>> {log}

        bcftools view \
            -e 'TYPE="indel" || TYPE="ref"' \
            -Ob \
            -o {output.intermediate_biallelic} \
            {output.intermediate_called} 2>> {log}

        bcftools norm \
            -m -both \
            -Ov \
            -o {output.vcf_snvs} \
            {output.intermediate_biallelic} 2>> {log}

        bcftools view \
            -e 'TYPE="indel"' \
            {output.intermediate_called} \
            -Ov -o {output.vcf_all} 2>> {log}
        """

rule ex_somatic_variant_rate:
    input:
        vcf_all = "results/{ex_sample}/{ex_sample}_all_positions.vcf"
    output:
        results = "results/{ex_sample}/{ex_sample}_somatic_variant_rate.txt"
    script:
        "../scripts/ex_somatic_variant_rate.py"
