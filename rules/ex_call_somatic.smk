"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: Filtered double stranded consensus (.bam)
Output: Somatic mutation calls (.vcf)

Somatic mutations are directly called against the filtered double stranded consensus BAM (single stranded overhangs and read 1 read 2 disagreements removed).
Some areas are masked using bed files (illumina difficlut regions, areas where germline depth is insufficient)

Author: James Phie
"""

#Creates mapping between experimental (codec) and matched sample (standard illumina sequencing) sample names
ex_to_ms = ex_samples.set_index("ex_sample")["ms_sample"].to_dict()

#Call somatic mutations on duplex bases with a quality of >=Q70 (~<200 false positives per diploid genome)
rule ex_call_somatic:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        ref = config["GRCh38_path"],
        #Bed file
    output:
        vcf_all = "results/{ex_sample}/{ex_sample}_all_positions.vcf",
        vcf_snvs = "results/{ex_sample}/{ex_sample}_variants.vcf"
    shell:
        """
        bcftools mpileup \
            --fasta-ref {input.ref} \
            --output-type u \
            --min-BQ 70 \
            --min-MQ 60 \
            --annotate AD,DP \
            --regions chr1:1000000-3000000 \
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
        "../scripts/somaticvariants.py"
