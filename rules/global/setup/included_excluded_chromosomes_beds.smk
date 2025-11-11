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
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create masks for included and excluded chromosomes
        included_excluded_chromosomes_beds.py \
            --fai {input.fai} \
            --exclude_bed {output.exclude_bed} \
            --include_bed {output.include_bed} \
            --included_chromosomes {params.included_chromosomes} \
            --log {log} 2>> {log}
        """
