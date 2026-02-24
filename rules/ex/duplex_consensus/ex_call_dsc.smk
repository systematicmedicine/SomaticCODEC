"""
Create duplex consensus (DSC)
    - All read 1's, and all read 2's belonging to a single molecular identifier are collapsed for single strand consensus (PCR duplicates)
    - All read 1 consensus and read 2 consensus belonging to a single molecular identifier are collapsed for duplex strand consensus 
    - Single stranded overhangs are retained for alignment purposes, but a Q of 2 is assigned to all single strand bases
    - Reads with >3 disagreements between overlapping paired end reads are excluded
"""

from definitions.paths.io import ex as EX

rule ex_call_dsc:
    input:
        bam = EX.UMI_GROUPED_BAM
    output:
        bam = temp(EX.RAW_DSC),
        metrics = EX.MET_CALL_DSC
    params:
        error_rate_pre_umi = config["sci_params"]["ex_call_dsc"]["error_rate_pre_umi"],
        error_rate_post_umi = config["sci_params"]["ex_call_dsc"]["error_rate_post_umi"],
        min_input_base_quality = config["sci_params"]["ex_call_dsc"]["min_input_base_quality"],
        min_read_pairs = config["sci_params"]["ex_call_dsc"]["min_read_pairs"],
        min_duplex_length = config["sci_params"]["ex_call_dsc"]["min_duplex_length"],
        max_duplex_disagreement_rate = config["sci_params"]["ex_call_dsc"]["max_duplex_disagreement_rate"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_call_dsc.log"
    benchmark:
        "logs/{ex_sample}/ex_call_dsc.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
       # Set memory limit
       ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Call duplex consensus
        JAVA_OPTS="-Xmx{resources.memory}g -Djava.io.tmpdir=tmp" fgbio \
            --compression={params.compression_level} \
            CallCodecConsensusReads \
            --threads {threads} \
            -i {input.bam} \
            -o {output.bam} \
            --error-rate-pre-umi {params.error_rate_pre_umi} \
            --error-rate-post-umi {params.error_rate_post_umi} \
            --min-input-base-quality {params.min_input_base_quality} \
            --min-read-pairs {params.min_read_pairs} \
            --min-duplex-length {params.min_duplex_length} \
            --max-duplex-disagreement-rate {params.max_duplex_disagreement_rate} \
            --stats {output.metrics} 2>> {log}
        """