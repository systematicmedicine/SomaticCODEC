"""
Obtains the germline contexts for positions where somatic variants were called
"""

import helpers.get_metadata as md
from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ex_somatic_variant_germline_contexts:
    input:
        ms_pileup_bcf = lambda wc: MS.PILEUP_INT.format(
            ms_sample=md.get_ex_to_ms_sample_map(config)[wc.ex_sample]
            ),
        ex_somatic_vcf = EX.CALLED_SNVS
    output:
        contexts_vcf = EX.MET_SNV_GERMLINE_CONTEXT
    log:
        L.EX_SOMATIC_VARIANT_GERMLINE_CONTEXTS
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_germline_context.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate germline contexts
        ex_somatic_variant_germline_contexts.py \
            --ms_pileup_bcf {input.ms_pileup_bcf} \
            --ex_somatic_vcf {input.ex_somatic_vcf} \
            --contexts_vcf {output.contexts_vcf} \
            --threads {threads} \
            --log {log} 2>> {log}
        """
