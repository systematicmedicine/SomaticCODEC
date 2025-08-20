"""
--- setup.smk ---

Rules for setting up the bioinformatics pipeline.

Authors: 
    - James Phie
    - Joshua Johnstone

"""
# Checks mapping of MS and EX samples in ms_samples.csv and ex_samples.csv
rule check_ex_ms_mapping:
    input:
        ex_csv = config["ex_samples_path"],
        ms_csv = config["ms_samples_path"]
    output:
        "logs/pipeline/check_ex_ms_mapping.done"
    log:
        "logs/pipeline/check_ex_ms_mapping.log"
    benchmark:
        "logs/pipeline/check_ex_ms_mapping.benchmark.txt"
    script:
        "../scripts/check_ex_ms_mapping.py"


# Creates index files from reference genome
rule bwamem_index_files:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        reference = config['GRCh38_path']
    output:
        amb = config['GRCh38_path'] + ".amb",
        ann = config['GRCh38_path'] + ".ann",
        bwt = config['GRCh38_path'] + ".bwt.2bit.64",
        pac = config['GRCh38_path'] + ".pac",
        sa = config['GRCh38_path'] + ".0123"
    log:
        "logs/pipeline/bwamem_index_files.log"
    benchmark:
        "logs/pipeline/bwamem_index_files.benchmark.txt"
    threads:
        max(1, os.cpu_count() // 4)
    shell:
        """
        bwa-mem2 index {input.reference} 2>> {log}
        """

rule samtools_index_files:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        reference = config['GRCh38_path']
    output:
        fai = config['GRCh38_path'] + ".fai"
    log:
        "logs/pipeline/samtools_index_files.log"
    benchmark:
        "logs/pipeline/samtools_index_files.benchmark.txt"
    shell:
        """
        samtools faidx {input.reference} 2>> {log}
        """

rule picard_sequence_dict:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        ref = config["GRCh38_path"]
    output:
        dictf = config["GRCh38_path"].replace(".fna", ".dict")
    log:
        "logs/pipeline/picard_sequence_dict.log"
    benchmark:
        "logs/pipeline/picard_sequence_dict.benchmark.txt"
    shell:
        """
        picard CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """

"""
Generate adapter FASTA files for demultiplexing and trimming
""" 
rule ex_generate_adapter_fastas:
    input:
        mapping_check = "logs/pipeline/check_ex_ms_mapping.done",
        ex_lanes = config["ex_lanes_path"],
        ex_samples = config["ex_samples_path"],
        ex_adapters = config["ex_adapters_path"]
    output:
        adapter_fasta_outputs = expand(
            "tmp/{ex_lane}/{ex_lane}_{region}.fasta",
            ex_lane = md.get_ex_lane_ids(config),
            region = ["r1_start", "r1_end", "r2_start", "r2_end"]
        )
    log:
        "logs/pipeline/ex_generate_adapter_fastas.log"
    benchmark:
        "logs/pipeline/ex_generate_adapter_fastas.benchmark.txt"
    script:
        "../scripts/ex_generate_adapter_fastas.py"