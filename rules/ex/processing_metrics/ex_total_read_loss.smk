"""
Calculate the total read loss between raw FASTQ, and DSC immediately before variant calling
"""
rule ex_total_read_loss:
    input:
        input_fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_demux.fastq.gz",
        input_fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_demux.fastq.gz",
        dsc_final = "tmp/{ex_sample}/{ex_sample}_map_dsc_anno_filtered.bam"
    output:
        metrics = "metrics/{ex_sample}/{ex_sample}_total_read_loss.json"
    params:
        sample = "{ex_sample}"
    log:
        "logs/{ex_sample}/ex_total_read_loss.log"
    benchmark:
        "logs/{ex_sample}/ex_total_read_loss.benchmark.txt"
    threads:
        1
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Calculate total read loss
        ex_total_read_loss.py \
            --input_fastq1 {input.input_fastq1} \
            --input_fastq2 {input.input_fastq2} \
            --dsc_final {input.dsc_final} \
            --metrics {output.metrics} \
            --sample {params.sample} \
            --log {log} 2>> {log}
        """
