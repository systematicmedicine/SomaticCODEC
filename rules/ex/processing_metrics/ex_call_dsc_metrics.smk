"""
Calculate percentage of reads lost when calling DSC
"""
rule ex_call_dsc_metrics:
    input:
        pre_call_bam = "tmp/{ex_sample}/{ex_sample}_map_anno.bam",
        post_call_bam = "tmp/{ex_sample}/{ex_sample}_unmap_dsc.bam"
    output:
        call_dsc_metrics = "metrics/{ex_sample}/{ex_sample}_call_dsc_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_call_dsc_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_call_dsc_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate percentage reads lost
        ex_call_dsc_metrics.py \
            --pre_call_bam {input.pre_call_bam} \
            --post_call_bam {input.post_call_bam} \
            --call_dsc_metrics {output.call_dsc_metrics} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """