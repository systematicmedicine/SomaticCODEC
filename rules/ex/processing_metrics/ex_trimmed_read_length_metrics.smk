"""
Calculates the length of reads post trimming, outputs percentiles and zero-length reads
"""
rule ex_trimmed_read_length_metrics:
    input:
        r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_trimmed_read_length_metrics.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.log"
    benchmark:
        "logs/{ex_sample}/ex_trimmed_read_length_metrics.benchmark.txt" 
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_trimmed_read_length_metrics.py")