"""
Trim reads so that only inserts are remaining
    1. Trim 5' adapter sequences
    2. Trim 3' adapter sequences
    3. Trim additional bases from the 5' end (to account for short adapter sequences/A-tailing remnants)
    4. Trim additional bases from the 3' end (to account for short adapter sequences/A-tailing remnants)
"""

import helpers.get_metadata as md

rule ex_tc_trim_fastq:
    input:
        r1 = "tmp/{ex_technical_control}/{ex_technical_control}_r1_demux.fastq.gz",
        r2 = "tmp/{ex_technical_control}/{ex_technical_control}_r2_demux.fastq.gz",
    output:
        r1 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_tc.fastq.gz"),
        r2 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r2_trim_tc.fastq.gz"),
        trim5primejson = "metrics/{ex_technical_control}/{ex_technical_control}_trim_5prime_metrics_tc.json",
        r1_trim3primejson = "metrics/{ex_technical_control}/{ex_technical_control}_r1_trim_3prime_metrics_tc.json",
        r2_trim3primejson = "metrics/{ex_technical_control}/{ex_technical_control}_r2_trim_3prime_metrics_tc.json",
        intermediate_r1_1 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_adapters_tc.fastq.gz"),
        intermediate_r2_1 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r2_trim_adapters_tc.fastq.gz"),
        intermediate_r1_2 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r1_trim_adapters2_tc.fastq.gz"),
        intermediate_r2_2 = temp("tmp/{ex_technical_control}/{ex_technical_control}_r2_trim_adapters2_tc.fastq.gz")
    params:
        max_error_rate = config["sci_params"]["ex_tc_trim_fastq"]["max_error_rate"],
        min_adapter_overlap = config["sci_params"]["ex_tc_trim_fastq"]["min_adapter_overlap"],
        r1_cut_start = config["sci_params"]["ex_tc_trim_fastq"]["r1_cut_start"],
        r2_cut_start = config["sci_params"]["ex_tc_trim_fastq"]["r2_cut_start"],
        r1_cut_end = config["sci_params"]["ex_tc_trim_fastq"]["r1_cut_end"],
        r2_cut_end = config["sci_params"]["ex_tc_trim_fastq"]["r2_cut_end"],
        r1_start = lambda wc: md.get_ex_technical_control_adapter_dict(config)[wc.ex_technical_control]["r1_start"],
        r1_end = lambda wc: md.get_ex_technical_control_adapter_dict(config)[wc.ex_technical_control]["r1_end"],
        r2_start = lambda wc: md.get_ex_technical_control_adapter_dict(config)[wc.ex_technical_control]["r2_start"],
        r2_end = lambda wc: md.get_ex_technical_control_adapter_dict(config)[wc.ex_technical_control]["r2_end"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_technical_control}/ex_tc_trim_fastq.log"
    benchmark:
        "logs/{ex_technical_control}/ex_tc_trim_fastq.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          -g ^{params.r1_start} \
          -G ^{params.r2_start} \
          -o {output.intermediate_r1_1} \
          -p {output.intermediate_r2_1} \
          --compression-level {params.compression_level} \
          {input.r1} {input.r2} \
          --json={output.trim5primejson} 2>> {log}

        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          --overlap {params.min_adapter_overlap} \
          -b {params.r1_end} \
          -o {output.intermediate_r1_2} \
          --compression-level {params.compression_level} \
          {output.intermediate_r1_1} \
          --json={output.r1_trim3primejson} 2>> {log}

        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          --overlap {params.min_adapter_overlap} \
          -b {params.r2_end} \
          -o {output.intermediate_r2_2} \
          --compression-level {params.compression_level} \
          {output.intermediate_r2_1} \
          --json={output.r2_trim3primejson} 2>> {log}

          cutadapt \
          -j {threads} \
          -u {params.r1_cut_start} \
          -U {params.r2_cut_start} \
          -u {params.r1_cut_end} \
          -U {params.r2_cut_end} \
          -o {output.r1} \
          -p {output.r2} \
          --compression-level {params.compression_level} \
          {output.intermediate_r1_2} \
          {output.intermediate_r2_2} 2>> {log}
        """ 