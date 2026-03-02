"""
Positional distribution of called SNVs
"""

from definitions.paths.io import ex as EX

rule ex_snv_position_metrics:
    input:
        vcf_path = EX.CALLED_SNVS,
        index_path = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        metrics_json = EX.MET_SNV_POSITION_JSON,
        metrics_plot = EX.MET_SNV_POSITION_PDF
    params:
        included_chroms = config["sci_params"]["shared"]["included_chromosomes"],
        run_name = config["run_name"]
    log:
        "logs/{ex_sample}/ex_snv_position_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_snv_position_metrics.benchmark.txt"
    threads:
        1
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
