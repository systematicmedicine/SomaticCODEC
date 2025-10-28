"""
Calculates the distance to nearest SNV, for each SNV
"""
rule ex_snv_distance_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
    output:
        metrics_json = "metrics/{ex_sample}/{ex_sample}_snv_distance.json"
    log:
        "logs/{ex_sample}/ex_snv_distance_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_distance_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_snv_distance_metrics.py")