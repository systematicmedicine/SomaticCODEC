"""
Identify somatic variants present in multiple samples in a batch
"""

import helpers.get_metadata as md

rule ex_recurrent_variant_metrics:
    input:
        somatic_vcfs = expand("results/{ex_sample}/{ex_sample}_variants.vcf", ex_sample = md.get_ex_sample_ids(config)),
        germ_contaminant_vcfs = expand("results/{ex_sample}/{ex_sample}_germline_matches.vcf", ex_sample = md.get_ex_sample_ids(config))
    output:
        vcf_path = "results/batch/batch_recurrent_variants.vcf",
        metrics_path = "results/batch/batch_recurrent_variant_metrics.json"
    log:
        "logs/global_rules/batch_ex_recurrent_variant_metrics.log"
    benchmark:
        "logs/global_rules/batch_ex_recurrent_variant_metrics.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate recurrent variant metrics
        ex_recurrent_variant_metrics.py \
            --somatic_vcfs {input.somatic_vcfs} \
            --germ_contaminant_vcfs {input.germ_contaminant_vcfs} \
            --vcf_path {output.vcf_path} \
            --metrics_path {output.metrics_path} \
            --log {log} 2>> {log}
        """
