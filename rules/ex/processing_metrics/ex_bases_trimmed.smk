"""
Calculates the count and percentage of bases lost during ex_trim_fastq
"""
rule ex_bases_trimmed:
    input:
        pre_r1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        pre_r2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        post_r1 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz",
        post_r2 = "tmp/{ex_sample}/{ex_sample}_r1_trim.fastq.gz"
    output:
        json = "metrics/{ex_sample}/{ex_sample}_bases_trimmed.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_bases_trimmed.log"
    benchmark:
        "logs/{ex_sample}/ex_bases_trimmed.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_bases_trimmed.py")