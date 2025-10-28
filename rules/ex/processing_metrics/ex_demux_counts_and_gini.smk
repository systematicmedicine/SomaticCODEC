"""
Generates a summary file with demuxed adaptor counts and Gini coefficient for inequality between adaptors
"""
rule ex_demux_counts_and_gini:
    input:
        demux_metrics = "metrics/{ex_lane}/{ex_lane}_demux_metrics.txt"
    output:
        demux_gini = "metrics/{ex_lane}/{ex_lane}_demux_counts_and_gini.json"
    log:
        "logs/{ex_lane}/ex_demux_metrics_gini.log"
    benchmark:
        "logs/{ex_lane}/ex_demux_metrics_gini.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_demux_counts_and_gini.py")