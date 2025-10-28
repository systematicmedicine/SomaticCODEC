# Creates index files from reference genome

rule bwamem_index_files:
    input:
        reference = config["sci_params"]["global"]["reference_genome"]
    output:
        amb = config["sci_params"]["global"]["reference_genome"] + ".amb",
        ann = config["sci_params"]["global"]["reference_genome"] + ".ann",
        bwt = config["sci_params"]["global"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["sci_params"]["global"]["reference_genome"] + ".pac",
        sa = config["sci_params"]["global"]["reference_genome"] + ".0123"
    log:
        "logs/global_rules/bwamem_index_files.log"
    benchmark:
        "logs/global_rules/bwamem_index_files.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        bwa-mem2 index {input.reference} 2>> {log}
        """