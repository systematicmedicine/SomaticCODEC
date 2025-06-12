"""
--- ex_call_somatic.smk ---

Rules for calling somatic mutations

Input: Filtered double stranded consensus (.bam)
Output: Somatic mutation calls (.vcf)

Somatic mutations are directly called against the filtered double stranded consensus bam (single stranded overhangs and read 1 read 2 disagreements removed).
Some areas are masked using bed files (illumina difficlut regions, areas where germline depth is insufficient)

Author: James Phie
"""
# Create a basic samtools mpileup which lists all disagreements with reference at each position
rule ex_dsc_mpileup:
    input:
        pers_ref = lambda wc: f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_personalized_ref.fasta" #Rename based on ms pipeline
        masked = f"tmp/{ex_to_ms[wc.ex_sample]}/{ex_to_ms[wc.ex_sample]}_masked_regions.bed" #Rename based on ms pipeline
        dsc_bam = "tmp/{ex_sample}/{ex_sample}_dsc_map_anno.bam" #Need to add the filtered bam here, ie. single strand overhangs and R1R2 disagree N bases removed
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

# Extract single nucleotide variant calls from the samtools mpileup file into vcf format
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
