# Creates reference .dict file

rule picard_sequence_dict:
    input:
        ref = config["sci_params"]["global"]["reference_genome"]
    output:
        dictf = os.path.splitext(config["sci_params"]["global"]["reference_genome"])[0] + ".dict"
    log:
        "logs/global_rules/picard_sequence_dict.log"
    benchmark:
        "logs/global_rules/picard_sequence_dict.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit and create dict file
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """