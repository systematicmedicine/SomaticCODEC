"""
Positional distribution of called SNVs
"""
rule ex_snv_position_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        index_path = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        metrics_json = "metrics/{ex_sample}/{ex_sample}_snv_position_metrics.json",
        metrics_plot = "metrics/{ex_sample}/{ex_sample}_snv_position_plot.pdf"
    params:
        included_chroms = config["sci_params"]["global"]["included_chromosomes"],
        run_name = config["run_name"]
    log:
        "logs/{ex_sample}/ex_snv_position_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_position_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_snv_position.R")