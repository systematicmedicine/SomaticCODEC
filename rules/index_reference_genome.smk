"""
--- index_reference_genome.smk ---

Generate all index files from the reference genome for alignment steps

Input: Reference genome (from config)
Output: Reference genome index files 

Author: James Phie

"""
# Creates index files from reference genome
rule bwamem_index_files:
    input:
        reference = config['GRCh38_path']
    output:
        amb = config['GRCh38_path'] + ".amb",
        ann = config['GRCh38_path'] + ".ann",
        bwt = config['GRCh38_path'] + ".bwt.2bit.64",
        pac = config['GRCh38_path'] + ".pac",
        sa = config['GRCh38_path'] + ".0123"
    log:
        "logs/bwamem_index_files.log"
    benchmark:
        "logs/bwamem_index_files.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 index {input.reference} 2>> {log}
        """

rule samtools_index_files:
    input:
        reference = config['GRCh38_path']
    output:
        fai = config['GRCh38_path'] + ".fai"
    log:
        "logs/samtools_index_files.log"
    benchmark:
        "logs/samtools_index_files.benchmark.txt"
    shell:
        """
        samtools faidx {input.reference} 2>> {log}
        """

rule picard_sequence_dict:
    input:
        ref = config["GRCh38_path"]
    output:
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    log:
        "logs/picard_sequence_dict.log"
    benchmark:
        "logs/picard_sequence_dict.benchmark.txt"
    shell:
        """
        picard CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """