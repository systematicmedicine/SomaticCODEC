"""
Creates reference .fai file
"""

rule samtools_index_files:
    input:
        reference = config["sci_params"]["global"]["reference_genome"]
    output:
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    log:
        "logs/global_rules/samtools_index_files.log"
    benchmark:
        "logs/global_rules/samtools_index_files.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create index file
        samtools faidx {input.reference} 2>> {log}
        """