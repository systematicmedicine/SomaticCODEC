# Generates a summary of key metrics for ms fastqc reports

rule ms_fastqc_summary_metrics:
    input:
        fastqc_files = ["metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc.txt",
        "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc.txt" ]
    output:       
        ms_raw_summary_r1 = "metrics/{ms_sample}/{ms_sample}_r1_raw_fastqc_summary.json",
        ms_raw_summary_r2 = "metrics/{ms_sample}/{ms_sample}_r2_raw_fastqc_summary.json",
        ms_filter_summary_r1 = "metrics/{ms_sample}/{ms_sample}_filter_r1_fastqc_summary.json",
        ms_filter_summary_r2 = "metrics/{ms_sample}/{ms_sample}_filter_r2_fastqc_summary.json"
    params:
        sample = "{ms_sample}"
    log:
        "logs/{ms_sample}/ms_fastqc_summary_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_fastqc_summary_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "fastqc_summary_metrics.py")