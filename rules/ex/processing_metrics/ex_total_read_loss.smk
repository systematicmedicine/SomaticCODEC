"""
Calculate the total read loss between raw FASTQ, and DSC immediately before variant calling
"""
rule ex_total_read_loss:
    input:
        input_fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        input_fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        file_path = "metrics/{ex_sample}/{ex_sample}_total_read_loss.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_total_read_loss.log"
    benchmark:
        "logs/{ex_sample}/ex_total_read_loss.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    script:
        os.path.join(workflow.basedir, "scripts", "ex_total_read_loss.py")