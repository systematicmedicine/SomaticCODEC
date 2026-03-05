"""
Creates reference .dict file
"""

from definitions.paths import log as L

rule picard_sequence_dict:
    input:
        ref = config["sci_params"]["shared"]["reference_genome"]
    output:
        dictf = os.path.splitext(config["sci_params"]["shared"]["reference_genome"])[0] + ".dict"
    log:
        L.PICARD_SEQUENCE_DICT
    benchmark:
        "logs/shared_rules/picard_sequence_dict.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit and create dict file
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CreateSequenceDictionary \
            R={input.ref} \
            O={output.dictf} 2>> {log}
        """