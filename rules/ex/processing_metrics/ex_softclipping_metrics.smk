"""
Quantifies how much soft clipping is present in final DSC
"""
rule ex_softclipping_metrics:
    input:
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json"
    log:
        "logs/{ex_sample}/ex_softclipping_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_softclipping_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate softclipping metrics
        ex_softclipping_metrics.py \
            --dsc_final {input.dsc_final} \
            --metrics {output.metrics} \
            --log {log} 2>> {log}
        """
