# Generates ms alignment metrics

rule ms_alignment_metrics:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_deduped_map.bam"
    output:
        stats = "metrics/{ms_sample}/{ms_sample}_alignment_stats.txt",
        insert_metrics = "metrics/{ms_sample}/{ms_sample}_insert_size_metrics.txt",
        insert_hist = "metrics/{ms_sample}/{ms_sample}_insert_size_histogram.pdf"
    log:
        "logs/{ms_sample}/ms_alignment_metrics.log"
    benchmark:
        "logs/{ms_sample}/ms_alignment_metrics.benchmark.txt"
    resources:
        memory = config["infrastructure"]["memory"]["light"]
    shell:
        """
        # Generate alignment metrics
        samtools flagstat {input.bam} > {output.stats} 2>> {log}

        # Generate insert size metrics
        picard -Xmx{resources.memory}g -Djava.io.tmpdir=tmp CollectInsertSizeMetrics \
            I={input.bam} \
            O={output.insert_metrics} \
            H={output.insert_hist} 2>> {log}
        """ 