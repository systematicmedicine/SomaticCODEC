"""
Trims FASTQ files
    - Spacer from 5' end of reads
    - Adaptors
    - Poly-G artifacts (>10 Gs at 3' end)
    - Bases of quality < qual_trim_threshold from read ends
"""
# Rule depends on output lists defined in pipeline_outputs.smk
include: os.path.join(workflow.basedir, "definitions", "outputs", "pipeline_outputs.smk")

import helpers.get_metadata as md
from definitions.paths.io import ms as MS

rule ms_trim_fastq:
    input:
        shared_setup = shared_setup,
        ms_samples = config["metadata"]["ms_samples_metadata"],
        r1 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][0],
        r2 = lambda wc: md.get_ms_sample_fastqs(config)[wc.ms_sample][1]
    output:
        intermediate_spacer_removed_r1 = temp(MS.TRIM_FASTQ_INT_R1),
        intermediate_spacer_removed_r2 = temp(MS.TRIM_FASTQ_INT_R2),
        r1 = temp(MS.TRIMMED_FASTQ_R1),
        r2 = temp(MS.TRIMMED_FASTQ_R2),
        metrics = MS.MET_TRIM_FASTQ
    params:
        adaptor_1 = config["sci_params"]["ms_trim_fastq"]["adaptor_1"],
        adaptor_2 = config["sci_params"]["ms_trim_fastq"]["adaptor_2"],
        spacer_length = config["sci_params"]["ms_trim_fastq"]["spacer_length"],
        qual_trim_threshold = config["sci_params"]["ms_trim_fastq"]["qual_trim_threshold"],
        max_error_rate = config["sci_params"]["ms_trim_fastq"]["max_error_rate"],
        min_overlap = config["sci_params"]["ms_trim_fastq"]["min_overlap"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_trim_fastq.log"
    benchmark:
        "logs/{ms_sample}/ms_trim_fastq.benchmark.txt"
    threads: 
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Remove spacer
        printf "##### Spacer removal #####\n" > {output.metrics}
        cutadapt \
          -j {threads} \
          -u {params.spacer_length} \
          -U {params.spacer_length} \
          -o {output.intermediate_spacer_removed_r1} \
          -p {output.intermediate_spacer_removed_r2} \
          --compression-level {params.compression_level} \
          {input.r1} {input.r2} \
          --report=full >> {output.metrics} 2>> {log}
        
        # Trim adaptors, poly-G artifacts, and low quality bases
        printf "\n\n##### Adapter/quality trimming #####\n" >> {output.metrics}
        cutadapt \
            -j {threads} \
            -a {params.adaptor_1} \
            -A {params.adaptor_1} \
            -a {params.adaptor_2} \
            -A {params.adaptor_2} \
            -a "G{{10}}" \
            -A "G{{10}}" \
            --quality-cutoff {params.qual_trim_threshold} \
            -e {params.max_error_rate} \
            -O {params.min_overlap} \
            -o {output.r1} \
            -p {output.r2} \
            --compression-level {params.compression_level} \
            {output.intermediate_spacer_removed_r1} {output.intermediate_spacer_removed_r2} \
            --report=full >> {output.metrics} 2>> {log}
        """