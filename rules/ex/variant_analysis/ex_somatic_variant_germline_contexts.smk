"""
Obtains the germline contexts for positions where somatic variants were called
"""

import scripts.helpers.get_metadata as md

rule ex_somatic_variant_germline_contexts:
    input:
        ms_pileup_bcf = lambda wc: (
            f"tmp/{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}/"
            f"{md.get_ex_to_ms_sample_map(config)[wc.ex_sample]}_ms_pileup.bcf"
        ),
        ex_somatic_vcf = "results/{ex_sample}/{ex_sample}_variants.vcf"
    output:
        vcf = "results/{ex_sample}/{ex_sample}_somatic_variant_germline_contexts.vcf"
    log:
        "logs/{ex_sample}/ex_somatic_variant_germline_context.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_germline_context.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_somatic_variant_germline_contexts.py")