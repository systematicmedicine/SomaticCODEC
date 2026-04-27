"""
Call somatic SNVs

- Somatic mutations are directly called against the filtered double stranded consensus BAM 
(single stranded overhangs and read 1 read 2 disagreements removed).

- Some areas are masked using bed files (illumina difficlut regions, areas where germline depth 
is insufficient)
"""

from definitions.paths.io import ex as EX
from definitions.paths.io import ms as MS
from definitions.paths import log as L
from definitions.paths import benchmark as B

rule ex_call_somatic_snv:
    input:
        bam = EX.FILTERED_DSC,
        bai = EX.FILTERED_DSC_INDEX,
        ref = config["sci_params"]["reference_files"]["genome"]["f"],
        include_bed = MS.INCLUDE_BED
    output:
        # Intermediate files
        intermediate_mpileup = temp(EX.CALL_SOMATIC_SNV_INT1),
        intermediate_called = temp(EX.CALL_SOMATIC_SNV_INT2 ),
        vcf_all = temp(EX.CALL_SOMATIC_SNV_INT3),
        intermediate_biallelic = temp(EX.CALL_SOMATIC_SNV_INT4),

        # Rule output
        vcf_snvs = protected(EX.CALLED_SNVS)

    params:
        max_base_quality = config["sci_params"]["ex_call_somatic_snv"]["max_base_quality"],
        min_base_quality = config["sci_params"]["ex_call_somatic_snv"]["min_base_quality"],
        min_mapping_quality = config["sci_params"]["ex_call_somatic_snv"]["min_mapping_quality"],
        compression_level = config["infrastructure"]["compression"]["gzip_level"]
    log:
        L.EX_CALL_SOMATIC_SNV
    benchmark:
        B.EX_CALL_SOMATIC_SNV
    threads:
        config["infrastructure"]["threads"]["heavy"]
    resources:
        memory = config["infrastructure"]["memory"]["heavy"]
    shell:
        """
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}
        
        # Create pileup
        bcftools mpileup \
            --threads {threads} \
            --fasta-ref {input.ref} \
            --output-type b \
            --count-orphans \
            --max-BQ {params.max_base_quality} \
            --min-BQ {params.min_base_quality} \
            --min-MQ {params.min_mapping_quality} \
            --no-BAQ \
            --annotate AD,DP \
            --regions-file {input.include_bed} \
            --output-type b{params.compression_level} \
            {input.bam} \
            -o {output.intermediate_mpileup} 2>> {log}

        # Call somatic variants
        bcftools call \
            --threads {threads} \
            --multiallelic-caller \
            --keep-alts \
            --output-type b{params.compression_level} \
            -o {output.intermediate_called} \
            {output.intermediate_mpileup} 2>> {log}

        # Create VCF with every unmasked position excluding INDELs
        bcftools view \
            --threads {threads} \
            -e 'TYPE="indel"' \
            {output.intermediate_called} \
            -Ov -o {output.vcf_all} 2>> {log}

        # Create VCF with only alternate alleles
        bcftools view \
            --threads {threads} \
            -e 'TYPE="indel" || TYPE="ref"' \
            --output-type b{params.compression_level} \
            -o {output.intermediate_biallelic} \
            {output.intermediate_called} 2>> {log}

        # Split multiallelic sites into multiple lines
        bcftools norm \
            --threads {threads} \
            -m -both \
            -Ov \
            -o {output.vcf_snvs} \
            {output.intermediate_biallelic} 2>> {log}
        """
