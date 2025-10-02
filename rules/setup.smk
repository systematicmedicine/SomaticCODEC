"""
--- setup.smk ---

Rules for setting up the bioinformatics pipeline.
    - Checking configs and inputs
    - Generating index and BED files
    - Setting up log files

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
        "logs/global_rules/check_ex_ms_mapping.done"
    resources:
        memory = config["resources"]["memory"]["light"]
    log:
        "logs/global_rules/check_ex_ms_mapping.log"
    benchmark:
        "logs/global_rules/check_ex_ms_mapping.benchmark.txt"
    script:
        "../scripts/check_ex_ms_mapping.py"


# Checks that chromosomes included for variant calling are present in reference and precomputed BEDs
rule check_included_chromosomes_present:
    input:
        fai = config["files"]["reference_genome"] + ".fai",
        precomputed_masks = config["files"]["precomputed_masks"]
    output:
        "logs/global_rules/check_included_chromosomes_present.done"
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"]
    log:
        "logs/global_rules/check_included_chromosomes_present.log"
    benchmark:
        "logs/global_rules/check_included_chromosomes_present.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    script:
        "../scripts/check_included_chromosomes_present.py"


# Creates a mask for chromosomes that will be excluded for variant calling 
    # e.g. chrUn, chr*_random, chrM, chrEBV
rule included_excluded_chromosomes_beds:
    input:
        fai = config["files"]["reference_genome"] + ".fai",
    output:
        exclude_bed = temp("tmp/downloads/excluded_chromosomes.bed"),
        include_bed = temp("tmp/downloads/included_chromosomes.bed")
    params:
        included_chromosomes = config["chroms"]["included_chromosomes"]
    log:
        "logs/global_rules/included_excluded_chromosomes_beds.log"
    benchmark:
        "logs/global_rules/included_excluded_chromosomes_beds.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    run:
        # Define chromosomes included for variant calling
        included_chromosomes = set(params.included_chromosomes)

        # Load the .fai and filter
        with open(input.fai) as fai_in, open(output.exclude_bed, "w") as bed_out:
            for line in fai_in:
                chrom, length, *_ = line.strip().split("\t")
                if chrom not in included_chromosomes:
                    bed_out.write(f"{chrom}\t0\t{length}\n")

        with open(input.fai) as fai_in, open(output.include_bed, "w") as bed_out:
            for line in fai_in:
                chrom, length, *_ = line.strip().split("\t")
                if chrom in included_chromosomes:
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
        "logs/global_rules/bwamem_index_files.log"
    benchmark:
        "logs/global_rules/bwamem_index_files.benchmark.txt"
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
        "logs/global_rules/samtools_index_files.log"
    benchmark:
        "logs/global_rules/samtools_index_files.benchmark.txt"
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
        "logs/global_rules/picard_sequence_dict.log"
    benchmark:
        "logs/global_rules/picard_sequence_dict.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """

# Creates index files for input VCFs
rule tabix_index_files:
    input:
        germline_vcf = config["files"]["known_germline_variants"]
    output:
        germline_tbi = config["files"]["known_germline_variants"] + ".tbi"
    log:
        "logs/global_rules/tabix_index_files.log"
    benchmark:
        "logs/global_rules/tabix_index_files.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        tabix -p vcf {input.germline_vcf} 2>> {log}
        """


# Logs disk space, memory, and cpu load at a defined interval
rule log_system_resource_usage:
    output:
        log = "logs/global_rules/system_resource_usage.csv",
        done_file = "logs/global_rules/log_system_resource_usage.done"
    params:
        sleep_interval = config["rules"]["log_system_resource_usage"]["sleep_interval"],
        total_cores = int(os.popen("nproc").read().strip()) - config["resources"]["threads"]["global_buffer"]
    log:
        "logs/global_rules/log_system_resource_usage.log"
    benchmark:
        "logs/global_rules/log_system_resource_usage.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        export SLEEP_INTERVAL={params.sleep_interval}
        export TOTAL_CORES={params.total_cores}
        
        bash scripts/monitor_system_resources.sh &

        touch {output.done_file}
        """


# Ensures that run_pipeline.log has been created
rule ensure_pipeline_log_exists:
    output:
        log = "logs/bin_scripts/run_pipeline.log"
    log:
        "logs/global_rules/ensure_pipeline_log_exists.log"
    benchmark:
        "logs/global_rules/ensure_pipeline_log_exists.benchmark.txt"
    resources:
        memory = config["resources"]["memory"]["light"]
    shell:
        """
        touch {output.log}
        """
