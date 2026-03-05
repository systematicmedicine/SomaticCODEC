"""
Creates index files from reference genome
"""

rule bwamem_index_files:
    input:
        reference = config["sci_params"]["shared"]["reference_genome"]
    output:
        amb = config["sci_params"]["shared"]["reference_genome"] + ".amb",
        ann = config["sci_params"]["shared"]["reference_genome"] + ".ann",
        bwt = config["sci_params"]["shared"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["sci_params"]["shared"]["reference_genome"] + ".pac",
        sa = config["sci_params"]["shared"]["reference_genome"] + ".0123"
    log:
        "logs/shared_rules/bwamem_index_files.log"
    benchmark:
        "logs/shared_rules/bwamem_index_files.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create index files
        bwa-mem2 index {input.reference} 2>> {log}
        """