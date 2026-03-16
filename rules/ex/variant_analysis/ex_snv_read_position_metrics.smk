"""
Read positions for called SNVs
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_snv_read_position_metrics:
    input:
        vcf_path = EX.CALLED_SNVS,
        bam_path = EX.FILTERED_DSC,
        bai_path = EX.FILTERED_DSC_INDEX,
        index_path = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        metrics_csv = EX.MET_SNV_READ_POSITION_CSV,
        metrics_plot = EX.MET_SNV_READ_POSITION_PDF
    log:
        L.EX_SNV_READ_POSITION_METRICS
    benchmark:
        B.EX_SNV_READ_POSITION_METRICS
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate SNV read position metrics
        ex_snv_read_position_metrics.py \
            --vcf {input.vcf_path} \
            --bam {input.bam_path} \
            --bai {input.bai_path} \
            --csv {output.metrics_csv} \
            --plot {output.metrics_plot} \
            --log {log} 2>> {log}
        """