"""

"""

rule ms_germ_risk_variant_metrics_summary:
    input: 
        variant_metrics = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt",
        pileup_bcf = "tmp/{ms_sample}/{ms_sample}_ms_pileup.bcf"
    output:
        summary = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics_summary.json"
    params:
        sample = "{ms_sample}",
        min_depth = config["sci_params"]["ms_low_depth_mask"]["min_depth"]
    log:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics_summary.log"
    benchmark:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics_summary.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ms_germ_risk_variant_metrics_summary.py")