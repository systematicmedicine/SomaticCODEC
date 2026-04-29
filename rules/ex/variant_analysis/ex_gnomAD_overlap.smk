"""
Determines how many called somatic variants are present in dataset of common germline variants
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_gnomAD_overlap:
    input:
        somatic_vcf = EX.CALLED_SNVS,
        germline_vcf = config["sci_params"]["reference_files"]["germline_variants"]["f"],
        germline_tbi = config["sci_params"]["reference_files"]["germline_variants"]["f"] + ".tbi"
    output:
        intermediate_somatic_bgz = temp(EX.MET_GNOMAD_OVERLAP_INT_BGZ),
        intermediate_somatic_tbi = temp(EX.MET_GNOMAD_OVERLAP_INT_TBI),
        germline_matches = EX.MET_GNOMAD_OVERLAP_VCF,
        metrics_file = EX.MET_GNOMAD_OVERLAP_JSON
    log:
        L.EX_GNOMAD_OVERLAP
    benchmark:
        B.EX_GNOMAD_OVERLAP
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate gnomAD overlap metrics
        ex_gnomAD_overlap.py \
            --somatic_vcf {input.somatic_vcf} \
            --germline_vcf {input.germline_vcf} \
            --intermediate_somatic_bgz {output.intermediate_somatic_bgz} \
            --intermediate_somatic_tbi {output.intermediate_somatic_tbi} \
            --germline_matches {output.germline_matches} \
            --metrics_file {output.metrics_file} \
            --log {log} 2>> {log}
        """
