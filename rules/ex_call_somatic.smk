"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: Filtered double stranded consensus (.bam)
Output: Somatic mutation calls (.vcf)

Somatic mutations are directly called against the filtered double stranded consensus BAM (single stranded overhangs and read 1 read 2 disagreements removed).
Some areas are masked using bed files (illumina difficlut regions, areas where germline depth is insufficient)

Authors: 
    - James Phie
"""


"""
Call somatic variants
    - Current version only calls SNVs
"""
rule ex_call_somatic_snv:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        ref = config["files"]["reference"],
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        vcf_all = temp("tmp/{ex_sample}/{ex_sample}_all_positions.vcf"), # Pileup of every unmasked position (except positions where indels present)
        vcf_snvs = protected("results/{ex_sample}/{ex_sample}_variants.vcf"), # Subset of vcf_all, where SNVs have been called
        intermediate_mpileup = temp("tmp/{ex_sample}/{ex_sample}_bcf_mpileup.bcf"),
        intermediate_called = temp("tmp/{ex_sample}/{ex_sample}_bcf_called.bcf"),
        intermediate_biallelic = temp("tmp/{ex_sample}/{ex_sample}_bcf_biallelic.bcf")
    params:
        max_base_quality = config["rules"]["ex_call_somatic_snv"]["max_base_quality"],
        min_base_quality = config["rules"]["ex_call_somatic_snv"]["min_base_quality"]
    log:
        "logs/{ex_sample}/ex_call_somatic_snv.log"
    benchmark:
        "logs/{ex_sample}/ex_call_somatic_snv.benchmark.txt"
    shell:
        """
        bcftools mpileup \
            --fasta-ref {input.ref} \
            --output-type b \
            --count-orphans \
            --max-BQ {params.max_base_quality} \
            --min-BQ {params.min_base_quality} \
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
