"""
Removes duplicate reads based on alignment and UMIs
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L

rule ms_remove_duplicates:
    input:
        bam = MS.MATE_INFO_BAM,
        bai = MS.MATE_INFO_BAM_INDEX
    output:
        intermediate_unsorted = temp(MS.REMOVE_DUPLICATES_INT),
        bam = temp(MS.DEDUPED_BAM),
        bai = temp(MS.DEDUPED_BAM_INDEX),
        dedup_metrics = MS.MET_DEDUP_REPORT
    params:
        duplicate_decision_method = config["sci_params"]["ms_remove_duplicates"]["duplicate_decision_method"],
        optical_duplicate_distance = config["sci_params"]["ms_remove_duplicates"]["optical_duplicate_distance"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.MS_REMOVE_DUPLICATES
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