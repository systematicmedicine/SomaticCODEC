"""
Generates a metrics file with the germline risk rate
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_germline_risk_rate:
    input:
        depth_pileup = MS.PILEUP_DEPTH,
        depth_alt_pileup = MS.GERMLINE_RISK_INT1,
    output:
        json = MS.MET_GERM_RISK_RATE
    log:
        L.MS_GERMLINE_RISK_RATE
    benchmark:
        B.MS_GERMLINE_RISK_RATE
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    threads:
        1
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate germline risk rate metrics
        ms_germline_risk_rate.py \
            --depth_pileup {input.depth_pileup} \
            --depth_alt_pileup {input.depth_alt_pileup} \
            --output_json {output.json} \
            --log {log} 2>> {log}
        """
