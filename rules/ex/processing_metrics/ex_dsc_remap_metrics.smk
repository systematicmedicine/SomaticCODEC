"""
Calculate DSC remapping metrics
    - ex_duplex_realignment: Percentage of reads which successfully aligned during DSC realignment
    - ex_duplex_mapQ: Percentage of reads with a mapQ score of at least 60
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_dsc_remap_metrics:
    input:
        bam = EX.REALIGNED_DSC,
    output:
        metrics = EX.MET_DSC_REMAP
    params:
        min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"],
        sample = "{ex_sample}"
    log:
        L.EX_DSC_REMAP_METRICS
    benchmark:
        B.EX_DSC_REMAP_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate DSC remapping metrics
        ex_dsc_remap_metrics.py \
            --bam {input.bam} \
            --metrics {output.metrics} \
            --min_mapq {params.min_mapq} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
