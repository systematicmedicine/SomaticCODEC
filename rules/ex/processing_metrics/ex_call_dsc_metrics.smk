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
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_call_dsc_metrics.py")