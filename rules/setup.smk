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
        ex_csv = config["files"]["ex_samples_metadata"],
        ms_csv = config["files"]["ms_samples_metadata"]
    output:
        "logs/pipeline/check_ex_ms_mapping.done"
    resources:
        memory = config["resources"]["memory"]["light"]
    log:
        "logs/pipeline/check_ex_ms_mapping.log"
    benchmark:
        "logs/pipeline/check_ex_ms_mapping.benchmark.txt"
    script:
        "../scripts/check_ex_ms_mapping.py"


# Checks that chromosomes included for variant calling are present in reference and precomputed BEDs
rule check_included_chromosomes_present:
    input:
        fai = config["files"]["reference_genome"] + ".fai",
        precomputed_masks = config["files"]["precomputed_masks"]
    output:
        "logs/pipeline/check_included_chromosomes_present.done"
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"]
    log:
        "logs/pipeline/check_included_chromosomes_present.log"
    benchmark:
        "logs/pipeline/check_included_chromosomes_present.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/check_included_chromosomes_present.py"


# Creates a mask for chromosomes that will be excluded for variant calling 
    # e.g. chrUn, chr*_random, chrM, chrEBV
rule mask_excluded_chromosomes:
    input:
        fai = config["files"]["reference_genome"] + ".fai",
    output:
        bed = temp("tmp/downloads/excluded_chromosomes.bed")
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"]
    resources:
        memory = config["resources"]["memory"]["light"]
    run:
        # Define chromosomes included for variant calling
        included_chromosomes = set(params.included_chromosomes)

        # Load the .fai and filter
        with open(input.fai) as fai_in, open(output.bed, "w") as bed_out:
            for line in fai_in:
                chrom, length, *_ = line.strip().split("\t")
                if chrom not in included_chromosomes:
                    bed_out.write(f"{chrom}\t0\t{length}\n")


# Creates index files from reference genome
rule bwamem_index_files:
    input:
        reference = config["files"]["reference_genome"]
    output:
        amb = config["files"]["reference_genome"] + ".amb",
        ann = config["files"]["reference_genome"] + ".ann",
        bwt = config["files"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["files"]["reference_genome"] + ".pac",
        sa = config["files"]["reference_genome"] + ".0123"
    log:
        "logs/pipeline/bwamem_index_files.log"
    benchmark:
        "logs/pipeline/bwamem_index_files.benchmark.txt"
    threads:
        config["resources"]["threads"]["moderate"]
    resources:
        memory = config["resources"]["memory"]["moderate"]
    shell:
        """
        bwa-mem2 index {input.reference} 2>> {log}
        """


# Creates reference .fai file
rule samtools_index_files:
    input:
        reference = config["files"]["reference_genome"]
    output:
        fai = config["files"]["reference_genome"] + ".fai"
    log:
        "logs/pipeline/samtools_index_files.log"
    benchmark:
        "logs/pipeline/samtools_index_files.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        samtools faidx {input.reference} 2>> {log}
        """

# Creates reference .dict file
rule picard_sequence_dict:
    input:
        ref = config["files"]["reference_genome"]
    output:
        dictf = os.path.splitext(config["files"]["reference_genome"])[0] + ".dict"
    log:
        "logs/pipeline/picard_sequence_dict.log"
    benchmark:
        "logs/pipeline/picard_sequence_dict.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """


# Generates adapter FASTA files for demultiplexing and trimming
rule ex_generate_adapter_fastas:
    input:
        ex_lanes = config["files"]["ex_lanes_metadata"],
        ex_samples = config["files"]["ex_samples_metadata"],
        ex_adapters = config["files"]["ex_adapters_metadata"]
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
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/ex_generate_adapter_fastas.py"