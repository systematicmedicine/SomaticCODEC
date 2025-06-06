"""
--- ms_personal_ref.smk ---

Rules for ...

Input: Varient Filtered VCF
Output: Fasta

Author: Ben Barry
Dev Status: Not operational

"""
#generating the personal reference file
#note: -L chr1 indicates that chr1 is the only interval to be used.
#Caveats:
    # If there are multiple variants that start at a site, it chooses one of them randomly.
    # When there are overlapping indels (but with different start positions) only the first will be chosen.
    # This tool works only for SNPs and for simple indels (but not for things like complex substitutions).
rule ms_generate_reference:
    input:
        ref = "tmp/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna",
        var = rules.ms_filter_pass_variants.output.vcf
    output:
        fasta = "tmp/data/pseudoref/Sample01_personalised_ref.fasta"
    shell:
        """
        gatk FastaAlternateReferenceMaker \
        -R {input.ref} \
        -V {input.var} \
        -O {output.fasta} \
        -L chr1 \
        """