"""
--- ms_personal_ref.smk ---

Rules for ...

Input: Varient Filtered VCF
Output: Fasta

Author: Ben Barry
Dev Status: Not operational

"""

rule ms_generate_reference:
    input:
        ref = "tmp/data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna",
        var = rules.Hard_filter_variants.output.vcf
    output:
        fasta = "tmp/data/processed/Sample01_personalised_ref.fasta"
    shell:
        """
        gatk FastaAlternateReferenceMaker \
        -R {input.ref} \
        -V {input.var} \
        -O {output.fasta} \
        -L chr1
        """