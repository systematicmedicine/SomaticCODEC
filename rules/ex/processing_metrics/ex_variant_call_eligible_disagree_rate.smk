"""
Calculates the Watson vs Crick base disagreement rate at positions that would be eligible for somatic variant calling if disagreements were not present
"""

rule ex_variant_call_eligible_disagree_rate:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam",
        bai = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam.bai",
        include_bed = "tmp/{ex_sample}/{ex_sample}_include.bed"
    output:
        metrics_json = "metrics/{ex_sample}/{ex_sample}_variant_call_disagree_metrics.json"
    params:
        required_Q = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"],
        number_of_reads = config["sci_params"]["ex_variant_call_disagree_metrics"]["number_of_reads"],
    log:
        "logs/{ex_sample}/ex_variant_call_eligible_disagree_rate.log"
    benchmark:
        "logs/{ex_sample}/ex_variant_call_eligible_disagree_rate.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_variant_call_eligible_disagree_rate.py")