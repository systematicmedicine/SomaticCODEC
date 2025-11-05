"""
Map reads to reference genome
"""
rule ex_map:
    input:
        fastq1 = "tmp/{ex_sample}/{ex_sample}_r1_filter.fastq.gz",
        fastq2 = "tmp/{ex_sample}/{ex_sample}_r2_filter.fastq.gz",
        ref = config["sci_params"]["global"]["reference_genome"],
        amb = config["sci_params"]["global"]["reference_genome"] + ".amb",
        ann = config["sci_params"]["global"]["reference_genome"] + ".ann",
        bwt = config["sci_params"]["global"]["reference_genome"] + ".bwt.2bit.64",
        pac = config["sci_params"]["global"]["reference_genome"] + ".pac",
        sa = config["sci_params"]["global"]["reference_genome"] + ".0123"
    output:
        bam = temp("tmp/{ex_sample}/{ex_sample}_map.bam"),
        intermediate_sam = temp("tmp/{ex_sample}/{ex_sample}_map_tmp.sam")
    params:
        band_width = config["sci_params"]["ex_map"]["band_width"],
        clipping_penalty = config["sci_params"]["ex_map"]["clipping_penalty"],
        gap_extension_penalty = config["sci_params"]["ex_map"]["gap_extension_penalty"],
        gap_open_penalty = config["sci_params"]["ex_map"]["gap_open_penalty"],
        matching_score = config["sci_params"]["ex_map"]["matching_score"],
        mem_max_occurances = config["sci_params"]["ex_map"]["mem_max_occurances"],
        min_alignment_score_thresh = config["sci_params"]["ex_map"]["min_alignment_score_thresh"],
        min_seed_length = config["sci_params"]["ex_map"]["min_seed_length"],
        mismatch_penalty = config["sci_params"]["ex_map"]["mismatch_penalty"],
        reseed_factor = config["sci_params"]["ex_map"]["reseed_factor"],
        unpaired_read_penalty = config["sci_params"]["ex_map"]["unpaired_read_penalty"],
        z_dropoff = config["sci_params"]["ex_map"]["z_dropoff"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ex_sample}/ex_map.log"
    benchmark:
        "logs/{ex_sample}/ex_map.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Map reads
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
        {input.fastq1} {input.fastq2} > {output.intermediate_sam} 2>> {log}

        # Convert SAM to BAM
        samtools view \
        -@ {threads} \
        --output-fmt bam \
        --output-fmt-option level={params.compression_level} \
        -bS {output.intermediate_sam} > {output.bam} 2>> {log}
        """