"""
Calculates the distance to nearest SNV, for each SNV
"""

from definitions.paths.io import ex as EX

rule ex_snv_distance_metrics:
    input:
        vcf = EX.CALLED_SNVS
    output:
        metrics_json = EX.MET_SNV_DISTANCE
    log:
        "logs/{ex_sample}/ex_snv_distance_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_distance_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate SNV distance metrics
        ex_snv_distance_metrics.py \
            --vcf {input.vcf} \
            --metrics_json {output.metrics_json} \
            --log {log} 2>> {log}
        """
