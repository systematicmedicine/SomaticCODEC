# Generates ms duplication metrics

rule ms_duplication_metrics:
    input:
        dedup_metrics = "metrics/{ms_sample}/{ms_sample}_dedup_metrics.json"
    output:
        duplication_metrics = "metrics/{ms_sample}/{ms_sample}_duplication_metrics_ms.json"
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_duplication_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_duplication_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ms_duplication_metrics.py")