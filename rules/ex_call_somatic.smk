"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: ...
Output: ...

Author: ...

Temporary working comments:

# Personalized vcf name:
tmp/ms_hek1.1/ms_hek1.1.vcf
tmp/ms_hek1.1/ms_hek1.1.vcf.idx

# Personalized fasta name:

# Duplex bam name: 
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam
tmp/ex_hek1.1/ex_hek1.1_map_dsc_anno.bam.bai

"""
rule ex_dsc_mpileup:
    input:
        pers_ref = lambda wc: f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_personalized_ref.fasta" #Rename based on ms pipeline
        masked = f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_masked_regions.bed" #Rename based on ms pipeline
        dsc_bam = "tmp/{ex_sample}/{ex_sample}_dsc_map_anno.bam" #Rename
    output:
        mpileup = "tmp/{ex_sample}/{ex_sample}_dsc_mpileup.txt"
    threads: 
        x =
    shell:
        """
        samtools mpileup -f {input.pers_ref} \
            -l {input.masked} -B -q 0 -Q 0 \
            {input.dsc_bam} > {output.mpileup}
        """

rule ex_somatic_variants:
    input:
        mpileup = "tmp/{ex_sample}/{ex_sample}_dsc_mpileup.txt"
    output:
        vcf = "results/{ex_sample}_somatic_mutations.vcf"
    threads: 
        x =
    shell:
        """
        varscan mpileup2snp {input.mpileup} \
            --min-coverage 1 \
            --min-var-freq 0 \
            --strand-filter 0 \
            --min-reads2 1 \
            --min-avg-qual 0 \
            --p-value 1 \
            --output-vcf 1 > {output.vcf}
        """
