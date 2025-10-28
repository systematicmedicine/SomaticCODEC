"""
Calculate the somatic variant rate
"""
rule ex_somatic_variant_rate:
    input:
        vcf_all = "tmp/{ex_sample}/{ex_sample}_all_positions.vcf"
    output:
        results = "metrics/{ex_sample}/{ex_sample}_somatic_variant_rate.json"
    log:
        "logs/{ex_sample}/ex_somatic_variant_rate.log"
    benchmark:
        "logs/{ex_sample}/ex_somatic_variant_rate.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_somatic_variant_rate.py")