"""
Uses matched sample BAM to identify positions that may contain germline variants. 
    - Designed to favour sensitivty over specificity
"""

from definitions.paths.io import ms as MS
from definitions.paths.io import shared as S
from definitions.paths import log as L

rule ms_pileup:
    input:
        bam = MS.DEDUPED_BAM,
        bai = MS.DEDUPED_BAM_INDEX,
        ref = config["sci_params"]["shared"]["reference_genome"],
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai",
        included_chromsomes_bed = S.INCLUDED_CHROMS_BED
    output:
        intermediate_pileup = temp(MS.PILEUP_INT),
        vcf_depth = temp(MS.PILEUP_DEPTH)
    params:
        max_base_qual = config["sci_params"]["ms_pileup"]["max_base_qual"],
        max_depth = config["sci_params"]["ms_pileup"]["max_depth"],
        min_base_qual = config["sci_params"]["ms_pileup"]["min_base_qual"],
        min_depth = config["sci_params"]["ms_pileup"]["min_depth"],
        min_map_qual = config["sci_params"]["ms_pileup"]["min_map_qual"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.MS_PILEUP
    benchmark:
        "logs/{ms_sample}/ms_pileup.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["moderate"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Create pileup
        bcftools mpileup \
        --threads {threads} \
        --fasta-ref {input.ref} \
        --annotate AD,DP \
        --min-MQ {params.min_map_qual} \
        --min-BQ {params.min_base_qual} \
        --max-BQ {params.max_base_qual} \
        --max-depth {params.max_depth} \
        --no-BAQ \
        --regions-file {input.included_chromsomes_bed} \
        --output-type b{params.compression_level} \
        --output {output.intermediate_pileup} \
        {input.bam} 2>> {log}

        # Filter for variants with depth >= min_depth
        bcftools view \
        --threads {threads} \
        --include 'FMT/DP >= {params.min_depth}' \
        --output {output.vcf_depth} \
        {output.intermediate_pileup} 2>> {log}
        """