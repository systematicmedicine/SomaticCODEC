"""
Calculate duplex overlap metrics
"""
rule ex_duplex_overlap_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_duplex_overlap_metrics.json"
    log:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplex_overlap_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_duplex_overlap_metrics.py")