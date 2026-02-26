"""
Trim reads so that only inserts are remaining
    1. Trim 5' adapter sequences
    2. Trim 3' adapter sequences
    3. Trim additional bases from the 5' end (to account for short adapter sequences/A-tailing remnants)
    4. Trim additional bases from the 3' end (to account for short adapter sequences/A-tailing remnants)
    5. Remove any bases with a Q score less than set cutoff from the 3' end
"""

import helpers.get_metadata as md
from definitions.paths.io import ex as EX

rule ex_trim_fastq:
    input:
        # Demultiplexed FASTQs
        r1 = EX.DEMUXD_FASTQ_R1,
        r2 = EX.DEMUXD_FASTQ_R2,

        # Sample metadata
        ex_samples = config["metadata"]["ex_samples_metadata"],
        ex_adapters = config["metadata"]["ex_adapters_metadata"],

    output:
        # Trimmed FASTQs
        r1 = temp(EX.TRIMMED_FASTQ_R1),
        r2 = temp(EX.TRIMMED_FASTQ_R2),

        # Metrics files
        trim5primejson = EX.MET_TRIM_FASTQ_TRIM5P,
        r1_trim3primejson = EX.MET_TRIM_FASTQ_TRIM3PR1,
        r2_trim3primejson = EX.MET_TRIM_FASTQ_TRIM3PR2, 

        # Intermediate files
        int1_r1 = temp(EX.TRIM_FASTQ_INT1_R1),
        int1_r2 = temp(EX.TRIM_FASTQ_INT1_R2),
        int2_r1 = temp(EX.TRIM_FASTQ_INT2_R1),
        int2_r2 = temp(EX.TRIM_FASTQ_INT2_R2),

    params:
        max_error_rate = config["sci_params"]["ex_trim_fastq"]["max_error_rate"],
        min_adapter_overlap = config["sci_params"]["ex_trim_fastq"]["min_adapter_overlap"],
        quality_cutoff = config["sci_params"]["ex_trim_fastq"]["quality_cutoff"],
        r1_cut_start = config["sci_params"]["ex_trim_fastq"]["r1_cut_start"],
        r2_cut_start = config["sci_params"]["ex_trim_fastq"]["r2_cut_start"],
        r1_cut_end = config["sci_params"]["ex_trim_fastq"]["r1_cut_end"],
        r2_cut_end = config["sci_params"]["ex_trim_fastq"]["r2_cut_end"],
        r1_start = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r1_start"],
        r1_end = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r1_end"],
        r2_start = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r2_start"],
        r2_end = lambda wc: md.get_ex_sample_adapter_dict(config)[wc.ex_sample]["r2_end"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_trim_fastq.log"
    benchmark:
        "logs/{ex_sample}/ex_trim_fastq.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Trim 5' adapter sequences
        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          -g ^{params.r1_start} \
          -G ^{params.r2_start} \
          -o {output.int1_r1} \
          -p {output.int1_r2} \
          --compression-level {params.compression_level} \
          {input.r1} {input.r2} \
          --json={output.trim5primejson} 2>> {log}

        # Trim 3' adapter sequences from R1
        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          --overlap {params.min_adapter_overlap} \
          -b {params.r1_end} \
          -o {output.int2_r1} \
          --compression-level {params.compression_level} \
          {output.int1_r1} \
          --json={output.r1_trim3primejson} 2>> {log}

        # Trim 3' adapter sequences from R2
        cutadapt \
          -j {threads} \
          --error-rate {params.max_error_rate} \
          --overlap {params.min_adapter_overlap} \
          -b {params.r2_end} \
          -o {output.int2_r2} \
          --compression-level {params.compression_level} \
          {output.int1_r2} \
          --json={output.r2_trim3primejson} 2>> {log}

        # Trim additional bases and low quality bases
        cutadapt \
          -j {threads} \
          -u {params.r1_cut_start} \
          -U {params.r2_cut_start} \
          -u {params.r1_cut_end} \
          -U {params.r2_cut_end} \
          --quality-cutoff {params.quality_cutoff} \
          -o {output.r1} \
          -p {output.r2} \
          --compression-level {params.compression_level} \
          {output.int2_r1} {output.int2_r2} 2>> {log}
        """ 