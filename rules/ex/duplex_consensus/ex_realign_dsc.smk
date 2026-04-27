"""
Realign the DSC to the reference genome
    - This is required because the consensus sequence may differ from the sequences previously used for alignment
    - Single stranded overhangs are present in this BAM to assist with alignment (ideally filtered later)
"""

from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_realign_dsc:
    input:
        # Raw DSC
        bam = EX.RAW_DSC,

        # Reference genome
        ref = config["sci_params"]["reference_files"]["genome"]["f"],
        amb = config["sci_params"]["reference_files"]["genome"]["f"] + ".amb",
        ann = config["sci_params"]["reference_files"]["genome"]["f"] + ".ann",
        bwt = config["sci_params"]["reference_files"]["genome"]["f"] + ".bwt.2bit.64",
        pac = config["sci_params"]["reference_files"]["genome"]["f"] + ".pac",
        sa = config["sci_params"]["reference_files"]["genome"]["f"] + ".0123"
    output:
        # Intermediate files
        intermediate_fastq = temp(EX.REALIGN_DSC_INT1),
        intermediate_sam = temp(EX.REALIGN_DSC_INT2),
        unsorted_bam = temp(EX.REALIGN_DSC_INT3),
        
        # Rule output
        bam = temp(EX.REALIGNED_DSC),
    params:
        band_width = config["sci_params"]["ex_remap_dsc"]["band_width"],
        clipping_penalty = config["sci_params"]["ex_remap_dsc"]["clipping_penalty"],
        gap_extension_penalty = config["sci_params"]["ex_remap_dsc"]["gap_extension_penalty"],
        gap_open_penalty = config["sci_params"]["ex_remap_dsc"]["gap_open_penalty"],
        matching_score = config["sci_params"]["ex_remap_dsc"]["matching_score"],
        mem_max_occurances = config["sci_params"]["ex_remap_dsc"]["mem_max_occurances"],
        min_alignment_score_thresh = config["sci_params"]["ex_remap_dsc"]["min_alignment_score_thresh"],
        min_seed_length = config["sci_params"]["ex_remap_dsc"]["min_seed_length"],
        mismatch_penalty = config["sci_params"]["ex_remap_dsc"]["mismatch_penalty"],
        reseed_factor = config["sci_params"]["ex_remap_dsc"]["reseed_factor"],
        unpaired_read_penalty = config["sci_params"]["ex_remap_dsc"]["unpaired_read_penalty"],
        z_dropoff = config["sci_params"]["ex_remap_dsc"]["z_dropoff"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.EX_REALIGN_DSC
    benchmark:
        B.EX_REALIGN_DSC
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Convert BAM to FASTQ
        samtools fastq \
        -0 \
        {output.intermediate_fastq} \
        {input.bam} 2>> {log}

        # Realign reads
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
        -Y \
        {input.ref} \
        {output.intermediate_fastq} > {output.intermediate_sam} 2>> {log}

        # Convert SAM to BAM
        samtools view \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -@ {threads} \
        -bS \
        {output.intermediate_sam} > {output.unsorted_bam} 2>> {log}

        # Sort by read name
        samtools sort \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -n \
        -@ {threads} \
        -o {output.bam} \
        {output.unsorted_bam} 2>> {log}
        """