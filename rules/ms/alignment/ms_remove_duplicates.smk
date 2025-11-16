# Removes duplicate reads based on alignment and UMIs

rule ms_remove_duplicates:
    input:
        bam = "tmp/{ms_sample}/{ms_sample}_annotated_map.bam",
        bai = "tmp/{ms_sample}/{ms_sample}_annotated_map.bam.bai"
    output:
        bam = temp("tmp/{ms_sample}/{ms_sample}_deduped_map.bam"),
        bai = temp("tmp/{ms_sample}/{ms_sample}_deduped_map.bam.bai"),
        dedup_metrics = "metrics/{ms_sample}/{ms_sample}_dedup_metrics.json",
        intermediate_unsorted = temp("tmp/{ms_sample}/{ms_sample}_deduped_map_unsorted.bam")
    params:
        duplicate_decision_method = config["sci_params"]["ms_remove_duplicates"]["duplicate_decision_method"],
        optical_duplicate_distance = config["sci_params"]["ms_remove_duplicates"]["optical_duplicate_distance"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_remove_duplicates.log"
    benchmark:
        "logs/{ms_sample}/ms_remove_duplicates.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Remove duplicates
        samtools markdup \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -r \
        --json \
        -f {output.dedup_metrics} \
        --barcode-name \
        --mode {params.duplicate_decision_method} \
        -d {params.optical_duplicate_distance} \
        {input.bam} \
        {output.intermediate_unsorted} 2>> {log}

        # Sort deduplicated BAM
        samtools sort \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -o {output.bam} \
        {output.intermediate_unsorted} 2>> {log}

        # Create index file for deduplicated BAM
        samtools index {output.bam} 2>> {log}
        """