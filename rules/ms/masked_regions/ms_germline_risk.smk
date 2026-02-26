"""
Creates a BED file from germline risk VCF 
    - Includes variants with alt VAF >= a minimum alt VAF threshold
    - For deletions, the stop value of the BED region is determined by the length difference between ALT and REF alleles
    - For insertions and SNV's, the BED region is length 1
"""

from definitions.paths.io import ms as MS

rule ms_germline_risk:
    input:
        vcf = MS.PILEUP_DEPTH,
        ref_fai = config["sci_params"]["shared"]["reference_genome"] + ".fai"
    output:
        # Intermediate files
        intermediate_alt_vcf = temp(MS.GERMLINE_RISK_INT1),
        intermediate_del_unformatted = temp(MS.GERMLINE_RISK_INT2),
        intermediate_ins_unformatted = temp(MS.GERMLINE_RISK_INT3),
        intermediate_all_unformatted = temp(MS.GERMLINE_RISK_INT4),
        intermediate_del_unpadded = temp(MS.GERMLINE_RISK_INT5),
        intermediate_ins_unpadded = temp(MS.GERMLINE_RISK_INT6),
        ms_germ_del_bed = temp(MS.GERMLINE_RISK_INT7),
        ms_germ_ins_bed = temp(MS.GERMLINE_RISK_INT8),
        ms_germ_all_bed = temp(MS.GERMLINE_RISK_INT9),
        intermediate_cat_unsorted = temp(MS.GERMLINE_RISK_INT10),
        intermediate_cat_unmerged = temp(MS.GERMLINE_RISK_INT11),
        
        # Rule output
        ms_germ_risk_bed = temp(MS.GERMLINE_RISK_MASK)

    params:
        indel_padding_bases = config["sci_params"]["ms_germline_risk"]["indel_padding_bases"],
        min_alt_vaf = config["sci_params"]["ms_germline_risk"]["min_alt_vaf"]
    log:
        "logs/{ms_sample}/ms_germline_risk.log"
    benchmark:
        "logs/{ms_sample}/ms_germline_risk.benchmark.txt"
    threads:
        config["infrastructure"]["threads"]["light"]
    resources:
        memory = config["infrastructure"]["memory"]["extra_heavy"]
    shell:
        """   
        # Set memory limit
        ulimit -v $(( {resources.memory} * 1024 * 1024 )) 2>> {log}

        # Filter for alt VAF >= min_alt_vaf
        bcftools view \
        --threads {threads} \
        --include '(SUM(AD[0:*]) - AD[0:0]) / FMT/DP >= {params.min_alt_vaf}' \
        --output {output.intermediate_alt_vcf} \
        {input.vcf} 2>> {log}

        # Create separate BED files for insertions and deletions (to allow padding)
        vcf2bed --deletions < {output.intermediate_alt_vcf} > {output.intermediate_del_unformatted} 2>> {log}
        vcf2bed --insertions < {output.intermediate_alt_vcf} > {output.intermediate_ins_unformatted} 2>> {log}

        # Create unformatted BED file for all records in VCF
        vcf2bed --do-not-sort < {output.intermediate_alt_vcf} > {output.intermediate_all_unformatted} 2>> {log}

        # Format BED files
        cut -f1-3 {output.intermediate_del_unformatted} > {output.intermediate_del_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_ins_unformatted} > {output.intermediate_ins_unpadded} 2>> {log}
        cut -f1-3 {output.intermediate_all_unformatted} > {output.ms_germ_all_bed} 2>> {log}

        # Add padding bases on either side of deletion regions
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_del_unpadded} > {output.ms_germ_del_bed} 2>> {log}
        
        # Add padding bases on either side of insertion regions
        bedtools slop \
        -b {params.indel_padding_bases} \
        -g {input.ref_fai} \
        -i {output.intermediate_ins_unpadded} > {output.ms_germ_ins_bed} 2>> {log}

        # Combine insertion, deletion, and all variant masks
        cat {output.ms_germ_del_bed} \
        {output.ms_germ_ins_bed} \
        {output.ms_germ_all_bed} > {output.intermediate_cat_unsorted} 2>> {log}

        # Sort by chromosome then position
        sort {output.intermediate_cat_unsorted} -k1,1V -k2,2n > {output.intermediate_cat_unmerged} 2>> {log}

        # Merge adjacent regions
        bedtools merge -i {output.intermediate_cat_unmerged} > {output.ms_germ_risk_bed} 2>> {log}
        """