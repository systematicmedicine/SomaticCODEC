"""
Calculates DSC coverage metrics
"""

rule ex_dsc_coverage_metrics:
    input:
        bam_ex_dsc = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed",
        ref_fai = config["sci_params"]["global"]["reference_genome"] + ".fai"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_metrics.json",
        plot = "metrics/{ex_sample}/{ex_sample}_dsc_coverage_plot.html"
    params: 
        ex_depth_threshold = 1,
        ex_bq_threshold = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"]
    log:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_coverage_metrics.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate DSC coverage metrics
        ex_dsc_coverage_metrics.py \
            --threads {threads} \
            --ex_dsc_bam {input.bam_ex_dsc} \
            --include_bed {input.include_bed} \
            --ref_fai {input.ref_fai} \
            --output_json {output.json} \
            --output_plot {output.plot} \
            --ex_depth_threshold {params.ex_depth_threshold} \
            --ex_bq_threshold {params.ex_bq_threshold} \
            --log {log} 2>> {log}
        """