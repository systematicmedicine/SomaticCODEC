"""
Calculates the total read loss between raw FASTQ, and DSC immediately before variant calling
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_total_read_loss:
    input:
        input_fastq1 = EX.DEMUXD_FASTQ_R1,
        input_fastq2 = EX.DEMUXD_FASTQ_R2,
        dsc_final = EX.FILTERED_DSC
    output:
        metrics = EX.MET_TOTAL_READ_LOSS
    params:
        sample = "{ex_sample}"
    log:
        L.EX_TOTAL_READ_LOSS
    benchmark:
        B.EX_TOTAL_READ_LOSS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate total read loss
        ex_total_read_loss.py \
            --input_fastq1 {input.input_fastq1} \
            --input_fastq2 {input.input_fastq2} \
            --dsc_final {input.dsc_final} \
            --metrics {output.metrics} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
