"""
Generates a summary of key metrics for ex filter fastqc reports
"""
rule ex_fastqc_filter_summary_metrics:
    input:
        fastqc_files = ["metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics.txt",
        "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics.txt"]
    output:
        ex_filter_summary_r1 = "metrics/{ex_sample}/{ex_sample}_r1_fastqc_filter_metrics_summary.json",
        ex_filter_summary_r2 = "metrics/{ex_sample}/{ex_sample}_r2_fastqc_filter_metrics_summary.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_fastqc_filter_summary_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "fastqc_summary_metrics.py")