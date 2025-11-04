"""
Compares variant rate between chromosomes
"""
rule ex_chromosomal_variant_rate_metrics:
    input:
        vcf = "results/{ex_sample}/{ex_sample}_variants.vcf",
        fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        metrics = "results/{ex_sample}/{ex_sample}_chromosomal_variant_rate_metrics.json"
    params:
        included_chromosomes = config["sci_params"]["global"]["included_chromosomes"]
    log:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_chromosomal_variant_rate_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_chromosomal_variant_rate_metrics.py")