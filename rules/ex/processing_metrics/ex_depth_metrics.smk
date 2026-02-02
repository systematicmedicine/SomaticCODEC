"""
Generates depth metrics for the final EX DSC BAM
"""

rule ex_depth_metrics:
    input:
        bam_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed",
        ref_fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_depth_metrics.json"
    params:
        ex_bq_threshold = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]
    log:
        "logs/{ex_sample}/ex_depth_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_depth_metrics.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Generate coverage by depth metrics
        ex_depth_metrics.py \
            --threads {threads} \
            --ex_dsc_bam {input.bam_ex_dsc} \
            --include_bed {input.include_bed} \
            --ref_fai {input.ref_fai} \
            --ex_bq_threshold {params.ex_bq_threshold} \
            --output_json {output.json} \
            --log {log} 2>> {log}
        """