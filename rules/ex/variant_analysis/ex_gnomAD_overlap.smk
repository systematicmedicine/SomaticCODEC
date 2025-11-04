"""
Determines how many called somatic variants are present in dataset of common germline variants
"""
rule ex_gnomAD_overlap:
    input:
        somatic_vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        somatic_all_vcf = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf",
        germline_vcf = config["sci_params"]["global"]["known_germline_variants"],
        germline_tbi = config["sci_params"]["global"]["known_germline_variants"] + ".tbi"
    output:
        intermediate_somatic_bgz = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz"),
        intermediate_somatic_tbi = temp("tmp/{ex_sample}/{ex_sample}_indexed_somatic_vcf.bgz.tbi"),
        germline_matches = "results/{ex_sample}/{ex_sample}_germline_matches.vcf",
        metrics_file = "results/{ex_sample}/{ex_sample}_gnomAD_overlap_metrics.json"
    log:
        "logs/{ex_sample}/ex_gnomAD_overlap.log"
    benchmark:
        "logs/{ex_sample}/ex_gnomAD_overlap.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_gnomAD_overlap.py")