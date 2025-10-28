"""
Quantifies how much soft clipping is present in final DSC
"""
rule ex_softclipping_metrics:
    input:
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        file_path = "metrics/{ex_sample}/{ex_sample}_softclipping_metrics.json"
    log:
        "logs/{ex_sample}/ex_softclipping_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_softclipping_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_softclipping_metrics.py")