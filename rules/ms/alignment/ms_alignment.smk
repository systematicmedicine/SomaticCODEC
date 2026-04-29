"""
Aligns reads to reference genome
"""

from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ms_alignment:
    input:
        # FASTQ
        r1_processed = MS.FILTERED_FASTQ_R1,
        r2_processed = MS.FILTERED_FASTQ_R2,

        # Refrence genome
        ref = config["sci_params"]["reference_files"]["genome"]["f"],
        amb = config["sci_params"]["reference_files"]["genome"]["f"] + ".amb",
        ann = config["sci_params"]["reference_files"]["genome"]["f"] + ".ann",
        bwt = config["sci_params"]["reference_files"]["genome"]["f"] + ".bwt.2bit.64",
        pac = config["sci_params"]["reference_files"]["genome"]["f"] + ".pac",
        sa = config["sci_params"]["reference_files"]["genome"]["f"] + ".0123",

    output:
        intermediate_sam = temp(MS.RAW_SAM),
        bam = temp(MS.RAW_BAM)
    params:
        band_width = config["sci_params"]["ms_map"]["band_width"],
        clipping_penalty = config["sci_params"]["ms_map"]["clipping_penalty"],
        gap_extension_penalty = config["sci_params"]["ms_map"]["gap_extension_penalty"],
        gap_open_penalty = config["sci_params"]["ms_map"]["gap_open_penalty"],
        matching_score = config["sci_params"]["ms_map"]["matching_score"],
        mem_max_occurances = config["sci_params"]["ms_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["sci_params"]["ms_map"]["min_alignment_score_thresh"],
        min_seed_length = config["sci_params"]["ms_map"]["min_seed_length"],
        mismatch_penalty = config["sci_params"]["ms_map"]["mismatch_penalty"],
        reseed_factor = config["sci_params"]["ms_map"]["reseed_factor"],
        unpaired_read_penalty = config["sci_params"]["ms_map"]["unpaired_read_penalty"],
        z_dropoff = config["sci_params"]["ms_map"]["z_dropoff"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.MS_ALIGNMENT
    benchmark:
        B.MS_ALIGNMENT
    threads: 
        config["infrastructure"]["threads"]["moderate"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Align reads
        bwa-mem2 mem \
        -t {threads} \
        -k {params.min_seed_length} \
        -w {params.band_width} \
        -d {params.z_dropoff} \
        -r {params.reseed_factor} \
        -c {params.mem_max_occurances} \
        -A {params.matching_score} \
        -B {params.mismatch_penalty} \
        -O {params.gap_open_penalty} \
        -E {params.gap_extension_penalty} \
        -L {params.clipping_penalty} \
        -U {params.unpaired_read_penalty} \
        -T {params.min_alignment_score_thresh} \
        {input.ref} {input.r1_processed} {input.r2_processed} > {output.intermediate_sam} 2>> {log}

        # Convert SAM to BAM
        samtools view \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """