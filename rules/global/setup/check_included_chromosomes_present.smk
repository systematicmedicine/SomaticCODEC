# Checks that chromosomes included for variant calling are present in reference and precomputed BEDs
rule check_included_chromosomes_present:
    input:
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai",
        precomputed_masks = config["sci_params"]["global"]["precomputed_masks"]
    output:
        "logs/global_rules/check_included_chromosomes_present.done"
    params:
        included_chromosomes = config["sci_params"]["global"]["included_chromosomes"]
    log:
        "logs/global_rules/check_included_chromosomes_present.log"
    benchmark:
        "logs/global_rules/check_included_chromosomes_present.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "check_included_chromosomes_present.py")