"""
Calculates the Watson vs Crick base disagreement rate at positions that would be eligible for somatic variant calling if disagreements were not present
"""

from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ex_variant_call_eligible_disagree_rate:
    input:
        bam = EX.FILTERED_DSC,
        bai = EX.FILTERED_DSC_INDEX,
        include_bed = MS.INCLUDE_BED
    output:
        metrics_json = EX.MET_VAR_CALL_DISAGREE
    params:
        required_Q = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"],
        number_of_reads = config["sci_params"]["ex_variant_call_disagree_metrics"]["number_of_reads"],
        random_seed = config["sci_params"]["shared"]["random_seed"]
    log:
        L.EX_VARIANT_CALL_ELIGIBLE_DISAGREE_RATE
    benchmark:
        "logs/{ex_sample}/ex_variant_call_eligible_disagree_rate.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate disagree rate
        ex_variant_call_eligible_disagree_rate.py \
            --bam {input.bam} \
            --bai {input.bai} \
            --include_bed {input.include_bed} \
            --metrics_json {output.metrics_json} \
            --required_Q {params.required_Q} \
            --number_of_reads {params.number_of_reads} \
            --random_seed {params.random_seed} \
            --threads {threads} \
            --log {log} 2>> {log}
        """
