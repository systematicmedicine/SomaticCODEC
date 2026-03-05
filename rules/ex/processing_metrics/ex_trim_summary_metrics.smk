"""
Calculates the number of bases lost during ex_trim_fastq, the length percentiles for reads post trimming, percentage zero-length reads
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L

rule ex_trim_summary_metrics:
    input:
        demuxed_r1 = EX.DEMUXD_FASTQ_R1,
        demuxed_r2 = EX.DEMUXD_FASTQ_R2,
        trimmed_r1 = EX.TRIMMED_FASTQ_R1,
        trimmed_r2 = EX.TRIMMED_FASTQ_R2
    output:
        json = EX.MET_TRIM_SUMMARY
    log:
        L.EX_TRIM_SUMMARY_METRICS
    benchmark:
        "logs/{ex_sample}/ex_trim_summary_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate trimming summary metrics
        ex_trim_summary_metrics.py \
            --demuxed_r1 {input.demuxed_r1} \
            --demuxed_r2 {input.demuxed_r2} \
            --trimmed_r1 {input.trimmed_r1} \
            --trimmed_r2 {input.trimmed_r2} \
            --json {output.json} \
            --log {log} 2>> {log}
        """
