"""
Calculate DSC remapping metrics
    - ex_duplex_realignment: Percentage of reads which successfully aligned during DSC realignment
    - ex_duplex_mapQ: Percentage of reads with a mapQ score of at least 60
"""
rule ex_dsc_remap_metrics:
    input:
        bam = "tmp/{ex_sample}/{ex_sample}_map_dsc.bam",
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_dsc_remap_metrics.json"
    params:
        min_mapq = config["sci_params"]["ex_filter_dsc"]["min_mapq"],
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_dsc_remap_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_dsc_remap_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_dsc_remap_metrics.py")