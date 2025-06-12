"""
--- ms_personal_ref.smk ---

Rules for ...

Input: Varient Filtered VCF
Output: Fasta

Author: Ben Barry

"""
#generating the personal reference file
#note: -L chr1 indicates that chr1 is the only interval to be used.
#Caveats:
    # If there are multiple variants that start at a site, it chooses one of them randomly.
    # When there are overlapping indels (but with different start positions) only the first will be chosen.
    # This tool works only for SNPs and for simple indels (but not for things like complex substitutions).
rule ms_generate_reference:
    input:
        ref = HG38,
        var = rules.ms_filter_pass_variants.output.vcf
    output:
        fasta = "tmp/data/pseudoref/{sample}_personalised_ref.fasta"
    shell:
        """
        gatk FastaAlternateReferenceMaker \
        -R {input.ref} \
        -V {input.var} \
        -O {output.fasta} \
        -L chr1 \
        """



#NEED a metric to compare new ref to old ref