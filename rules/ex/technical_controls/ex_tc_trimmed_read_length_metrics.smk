"""

"""

rule ex_tc_trimmed_read_length_metrics:
    input:
        r1 = "tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_tc.fastq.gz",
        r2 = "tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_tc.fastq.gz"
    output:
        json = "metrics/{ex_technical_control}/{ex_technical_control}_trimmed_read_length_metrics_tc.json"
    params:
        sample = "{ex_technical_control}"
    log:
        "logs/{ex_technical_control}/ex_tc_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_technical_control}/ex_tc_trimmed_read_length_metrics.benchmark.txt" 
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_tc_trimmed_read_length_metrics.py")