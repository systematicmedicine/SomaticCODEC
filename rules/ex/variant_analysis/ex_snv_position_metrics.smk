"""
Positional distribution of called SNVs
"""
rule ex_snv_position_metrics:
    input:
        vcf_path = "results/{ex_sample}/{ex_sample}_variants.vcf",
        index_path = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        metrics_json = "results/{ex_sample}/{ex_sample}_snv_position_metrics.json",
        metrics_plot = "results/{ex_sample}/{ex_sample}_snv_position_plot.pdf"
    params:
        included_chroms = config["sci_params"]["global"]["included_chromosomes"],
        run_name = config["run_name"]
    log:
        "logs/{ex_sample}/ex_snv_position_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_position_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate SNV position metrics
        ex_snv_position.R \
            --vcf_path {input.vcf_path} \
            --index_path {input.index_path} \
            --metrics_json {output.metrics_json} \
            --metrics_plot {output.metrics_plot} \
            --included_chroms {params.included_chroms} \
            --run_name {params.run_name} \
            --log {log} 2>> {log}
        """
