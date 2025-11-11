"""
Calculates the distance to nearest SNV, for each SNV
"""
rule ex_snv_distance_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
    output:
        metrics_json = "results/{ex_sample}/{ex_sample}_snv_distance.json"
    log:
        "logs/{ex_sample}/ex_snv_distance_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_distance_metrics.benchmark.txt"
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
