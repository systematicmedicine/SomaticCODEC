# Generates metrics for germline risk variants
 
rule ms_germ_risk_variant_metrics:
    input: 
        vcf = "tmp/{ms_sample}/{ms_sample}_ms_germ_risk.vcf"
    output:
        stat = "metrics/{ms_sample}/{ms_sample}_germ_risk_variant_metrics.txt"
    log:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_germ_risk_variant_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Generate germline risk variant metrics
        bcftools stats -s - {input.vcf} > {output.stat} 2>> {log}
        """