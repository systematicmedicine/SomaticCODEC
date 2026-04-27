"""
Creates reference .dict file
"""

from definitions.paths import log as L
from definitions.paths import benchmark as B

rule picard_sequence_dict:
    input:
        ref = config["sci_params"]["reference_files"]["genome"]["f"]
    output:
        dictf = os.path.splitext(config["sci_params"]["reference_files"]["genome"]["f"])[0] + ".dict"
    log:
        L.PICARD_SEQUENCE_DICT
    benchmark:
        B.PICARD_SEQUENCE_DICT
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