"""
Generates a summary of key metrics for ex raw fastqc reports
"""
rule ex_fastqc_raw_summary_metrics:
    input:
        fastqc_files = ["metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics.txt",
        "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics.txt"]
    output:
        ex_lane_raw_summary_r1 = "metrics/{ex_lane}/{ex_lane}_r1_fastqc_raw_metrics_summary.json",
        ex_lane_raw_summary_r2 = "metrics/{ex_lane}/{ex_lane}_r2_fastqc_raw_metrics_summary.json"
    params:
        sample = "{ex_lane}"
    log:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.log"
    benchmark:
        "logs/{ex_lane}/ex_fastqc_raw_summary_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "fastqc_summary_metrics.py")
