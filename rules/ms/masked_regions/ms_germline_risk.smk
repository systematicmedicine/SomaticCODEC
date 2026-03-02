"""
Uses matched sample BAM to identify positions that may contain germline variants. 
    - Designed to favour sensitivty over specificity
"""

from definitions.paths.io import ms as MS
from definitions.paths.io import shared as S

rule ms_germline_risk:
    input:
        bam = MS.DEDUPED_BAM,
        bai = MS.DEDUPED_BAM_INDEX,
        ref = config["sci_params"]["shared"]["reference_genome"],
        fai = config["sci_params"]["shared"]["reference_genome"] + ".fai",
        included_chromsomes_bed = S.INCLUDED_CHROMS_BED
    output:
        intermediate_pileup = temp(MS.GERMLINE_RISK_INT),
        vcf_germ = temp(MS.GERMLINE_RISK_VCF)
    params:
        max_base_qual = config["sci_params"]["ms_germline_risk"]["max_base_qual"],
        max_depth = config["sci_params"]["ms_germline_risk"]["max_depth"],
        min_alt_vaf = config["sci_params"]["ms_germline_risk"]["min_alt_vaf"],
        min_base_qual = config["sci_params"]["ms_germline_risk"]["min_base_qual"],
        min_depth = config["sci_params"]["ms_low_depth_mask"]["min_depth"],
        min_map_qual = config["sci_params"]["ms_germline_risk"]["min_map_qual"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        "logs/{ms_sample}/ms_germline_risk.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_risk.benchmark.txt"
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

        # Filter for variants with VAF >= min_alt_vaf or depth < min_depth
        bcftools view \
        --threads {threads} \
        --include '(SUM(AD[0:*]) - AD[0:0]) / FMT/DP >= {params.min_alt_vaf} || FMT/DP < {params.min_depth}' \
        --output {output.vcf_germ} \
        {output.intermediate_pileup} 2>> {log}
        """