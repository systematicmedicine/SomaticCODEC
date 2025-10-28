"""
Duplication rate calculated based on unique UMI families output from ex_groupbyumi.
"""
rule ex_duplication_metrics:
    input:
        umi_metrics = "metrics/{ex_sample}/{ex_sample}_map_umi_metrics.txt"
    params:
        sample = "{ex_sample}"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_duplication_metrics.json"
    log:
        "logs/{ex_sample}/ex_duplication_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_duplication_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_duplication_metrics.py")