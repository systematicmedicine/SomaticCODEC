"""
--- index_reference_genome.smk ---

Generate all index files from the reference genome for alignment steps

Input: Reference genome (from config)
Output: Reference genome index files 

Author: James Phie

"""
# Creates index files from reference genome
rule ex_bwamem_index_files:
    input:
        reference = config['GRCh38_path']
    output:
        amb = config['GRCh38_path'] + ".amb",
        ann = config['GRCh38_path'] + ".ann",
        bwt = config['GRCh38_path'] + ".bwt.2bit.64",
        pac = config['GRCh38_path'] + ".pac",
        sa = config['GRCh38_path'] + ".sa"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 index {input.reference}
        """

rule ex_samtools_index_files:
    input:
        reference = config['GRCh38_path']
    output:
        fai = config['GRCh38_path'] + ".fai"
    shell:
        """
        samtools faidx {input.reference}
        """