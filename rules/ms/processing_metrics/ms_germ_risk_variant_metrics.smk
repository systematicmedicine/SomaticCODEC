"""
Generates metrics for germline risk variants
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B
 
rule ms_germ_risk_variant_metrics:
    input: 
        vcf = MS.GERMLINE_RISK_INT1
    output:
        stat = MS.MET_GERM_RISK_VARIANTS
    log:
        L.MS_GERM_RISK_VARIANT_METRICS
    benchmark:
        B.MS_GERM_RISK_VARIANT_METRICS
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    threads:
        1
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate germline risk variant metrics
        bcftools stats -s - {input.vcf} > {output.stat} 2>> {log}
        """