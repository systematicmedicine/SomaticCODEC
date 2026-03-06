"""
Moves the read pair UMI to readname
    - Cut 3bp from the start of the read 1 and read 2 sequence
    - Append read 1 3bp UMI sequence to the readname of read 1 and read 2
    - Append read 2 3bp UMI sequence after read 1 UMI in read 1 and read 2
""" 

import helpers.get_metadata as md
from definitions.paths.io import ex as EX
from definitions.paths import log as L
from definitions.paths import benchmark as B

# Rule
rule ex_extract_fastq_umis:
    input:
        # Raw FASTQs
        fastq1 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][0],
        fastq2 = lambda wc: md.get_ex_lane_fastqs(config)[wc.ex_lane][1],

        # Sample metadata
        ex_lanes = config["metadata"]["ex_lanes_metadata"],

        # All setup complete before rule can run
        setup_done = L.SETUP_DONE

    output:
        fastq1 = temp(EX.UMIXD_FASTQ_R1),
        fastq2 = temp(EX.UMIXD_FASTQ_R2)
    params:
        umi_length = config["sci_params"]["ex_extract_fastq_umis"]["umi_length"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.EX_EXTRACT_FASTQ_UMIS
    benchmark:
        B.EX_EXTRACT_FASTQ_UMIS
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Move UMIs from sequence to read name
        cutadapt \
          -j {threads} \
          --cut {params.umi_length} \
          -U {params.umi_length} \
          --rename='{{id}}:{{r1.cut_prefix}}{{r2.cut_prefix}}' \
          -o {output.fastq1} \
          -p {output.fastq2} \
          --compression-level {params.compression_level} \
          {input.fastq1} {input.fastq2} >> {log} 2>&1
        """