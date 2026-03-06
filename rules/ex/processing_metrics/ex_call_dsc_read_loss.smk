"""
Calculate percentage of reads lost when calling DSC
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_call_dsc_read_loss:
    input:
        pre_call_bam = EX.MATE_INFO_BAM,
        post_call_bam = EX.RAW_DSC
    output:
        call_dsc_metrics = EX.MET_CALL_DSC_READ_LOSS
    params:
        sample = "{ex_sample}"
    log:
        L.EX_CALL_DSC_READ_LOSS
    benchmark:
        B.EX_CALL_DSC_READ_LOSS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate percentage reads lost
        ex_call_dsc_read_loss.py \
            --pre_call_bam {input.pre_call_bam} \
            --post_call_bam {input.post_call_bam} \
            --call_dsc_metrics {output.call_dsc_metrics} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """