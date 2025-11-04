# Creates a mask for chromosomes that will be excluded for variant calling 
    # e.g. chrUn, chr*_random, chrM, chrEBV

rule included_excluded_chromosomes_beds:
    input:
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai",
    output:
        exclude_bed = temp("tmp/downloads/excluded_chromosomes.bed"),
        include_bed = temp("tmp/downloads/included_chromosomes.bed")
    params:
        included_chromosomes = config["sci_params"]["global"]["included_chromosomes"]
    log:
        "logs/global_rules/included_excluded_chromosomes_beds.log"
    benchmark:
        "logs/global_rules/included_excluded_chromosomes_beds.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
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